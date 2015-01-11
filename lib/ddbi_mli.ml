 open Core.Std
open Core_extended.Std
open Async.Std
open Pp.Infix

let arg_sep: Pp.t = Pp.break $ Pp.text "->" $ Pp.break

let print_regular_args: String.t List.t -> Pp.t =
  fun values ->
    Pp.list ~sep:arg_sep ~f:(fun element -> Pp.text element) values
    |> Pp.fgrp

let print_type_include
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "include Ddbi_type.Type with type t := t"

let print_record_name
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "val record_name: t -> String.t"

let print_version_decl
  : Ddbi_model.t -> Pp.t =
  fun {name} ->
    Pp.text "val version: Int.t"

let print_arg
  : Ddbi_field.t -> Pp.t =
  fun {Ddbi_field.name; field_type} ->
    let pp_name = if name = Ddbi_model.id_field_name
      then
        Pp.text "?"
        $ Pp.text name
      else
        Pp.text name in
    pp_name
    $ Pp.text ":"
    $ Ddbi_gen_base.print_field_type field_type

let print_args: Ddbi_field.t List.t -> Pp.t  =
  fun args ->
    Pp.list ~sep:arg_sep ~f:print_arg
    @@ List.filter ~f:(fun {name} -> not (name = Ddbi_model.version_field_name))
      args

let print_make: Ddbi_model.t -> Pp.t =
  fun {fields} ->
    Pp.text "val make: "
    $/ print_args fields
    $/ Pp.text "->"
    $/ Pp.text "Unit.t"
    $/ Pp.text "-> t"

let print_put: Unit.t -> Pp.t =
  fun () ->
    Pp.text "val put:"
    $/ Pp.text "Ddbi.t"
    $/ Pp.text "->"
    $/ Pp.text "t"
    $/ Pp.text "->"
    $/ Pp.text "(Ddbi.t, Exn.t) Deferred.Result.t"

let print_get
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "val get:"
    $/ Pp.text "Ddbi.t"
    $/ Pp.text "->"
    $/ Pp.text "String.t"
    $/ Pp.text "->"
    $/ Pp.text "(Ddbi.t * t Option.t, Exn.t) Deferred.Result.t"

let print_get_all
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "val all:"
    $/ Pp.text "Ddbi.t"
    $/ Pp.text "->"
    $/ Pp.text "(Ddbi.t * t List.t, Exn.t) Deferred.Result.t"

let print_create_store
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "val create_store:"
    $/ Pp.text "Ddbi.t"
    $/ Pp.text "->"
    $/ Pp.text "(Ddbi.t, Exn.t) Deferred.Result.t"

let print_file_of_t
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "val file_of_t:"
    $/ Pp.text "String.t"
    $/ Pp.text "->"
    $/ Pp.text "t"
    $/ Pp.text "->"
    $/ Pp.text "(Unit.t, Exn.t) Deferred.Result.t"

let print_t_of_file: Unit.t -> Pp.t =
  fun () ->
    Pp.text "val t_of_file:"
    $/ Pp.text "String.t"
    $/ Pp.text "->"
    $/ Pp.text "(t, Exn.t) Deferred.Result.t"

let print_foreign_model : Ddbi_model.foreign_model -> Pp.t =
  fun {name; model} ->
    (*val office: Dbm_system.t -> t -> (Dbm_system.t * Dbm_office.t, Exn.t) Deferred.Result.t*)
    (Pp.text "val"
     $/ Pp.text name
     $ Pp.text ": "
     |> Pp.hgrp)
    $ print_regular_args ["Ddbi.t"; "t";
                           "(Ddbi.t * " ^ model ^ ".t, Exn.t) Deferred.Result.t"]
    |> Pp.vgrp
    |> Ddbi_gen_base.scope

let print_foreign_models : Ddbi_model.t -> Pp.t =
  fun model ->
    Pp.list ~sep:(Pp.break) ~f:print_foreign_model model.foreign_models

let generate: Ddbi_model.t -> Pp.t =
  fun model ->
    Ddbi_gen_base.print_header ()
    $ Ddbi_gen_base.newline
    $/ Ddbi_gen_base.print_record model
    $/ Ddbi_gen_base.expr @@ print_type_include ()
    $/ Ddbi_gen_base.expr @@ print_record_name ()
    $/ Ddbi_gen_base.expr @@ print_make model
    $/ Ddbi_gen_base.expr @@ print_put ()
    $/ Ddbi_gen_base.expr @@ print_get ()
    $/ Ddbi_gen_base.expr @@ print_get_all ()
    $/ Ddbi_gen_base.expr @@ print_create_store ()
    $/ Ddbi_gen_base.expr @@ print_file_of_t ()
    $/ Ddbi_gen_base.expr @@ print_t_of_file ()
    $/ Ddbi_gen_base.expr @@ print_foreign_models model
