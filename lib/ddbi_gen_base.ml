open Core.Std
open Core_extended.Std
open Async.Std
open Pp.Infix

let default_indent = 4

let scope: Pp.t -> Pp.t =
  fun doc ->
    Pp.nest default_indent doc

let newline: Pp.t = Pp.text "\n"

let expr: Pp.t -> Pp.t =
  fun producer ->
    producer
    $  Pp.text "\n"
    |> Pp.nest default_indent
    |> Pp.fgrp

let print_field_type: String.t -> Pp.t  =
  fun field_type ->
    Pp.text field_type
    $ Pp.text ".t"

let print_field: Ddbi_field.t -> Pp.t =
  fun {Ddbi_field.name; field_type} ->
    Pp.text name
    $ Pp.text ": "
    $ print_field_type field_type

let record_field_sep = Pp.text ";" $ Pp.break

let print_fields: Ddbi_field.t List.t -> Pp.t  =
  Pp.list ~sep:record_field_sep ~f:print_field

let print_record: Ddbi_model.t -> Pp.t =
  fun {Ddbi_model.name; version; fields} ->
    Pp.text "type t = {"
    $ print_fields fields
    $ Pp.text "} with fields, sexp"
    |> expr

let print_header: Unit.t -> Pp.t =
  fun () ->
    Pp.text "open Core.Std\n"
    $ Pp.text "open Async.Std\n"
