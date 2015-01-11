open Core.Std
open Core_extended.Std
open Async.Std
open Pp.Infix

let print_name: Ddbi_model.t -> Pp.t =
  fun {name} ->
    Pp.text "let name = \""
    $ Pp.text name
    $ Pp.text "\""
    $ Pp.break
    $/ Pp.text "let model_name = name"
    |> Pp.vgrp

let print_version: Ddbi_model.t -> Pp.t =
  fun {version} ->
    Pp.text "let version = "
    $ Pp.text @@ Int.to_string version

let print_record_field
  : Ddbi_field.t -> Pp.t =
  fun {name; field_type} ->
    Pp.text name

let print_item_of_t_field
  : Ddbi_field.t -> Pp.t =
  fun {name; field_type} ->
    Pp.text "("
    $ Pp.text field_type
    $ Pp.text ".item_of_t \""
    $ Pp.text name
    $ Pp.text "\" "
    $ Pp.text name
    $ Pp.text ")"

let print_record
  : Ddbi_field.t List.t -> Pp.t =
  fun fields ->
    Pp.text "{"
    $ Pp.list ~sep:(Pp.text ";" $ Pp.break) ~f:print_record_field fields
    $ Pp.text "}"
    |> Pp.fgrp

let print_item_of_t
  : Ddbi_model.t -> Pp.t =
  fun {name; fields} ->
    Pp.text "let item_of_t ~name"
    $/ print_record fields
    $ Pp.text " ="
    $/ Pp.text "Ddbi_common.prefix_item"
    $/ Pp.text "~prefix:\""
    $ Pp.text name
    $ Pp.text "\""
    $/ (Pp.text "~item:("
        $ Pp.list ~sep:(Pp.break $ Pp.text "@ ") ~f:print_item_of_t_field fields
        |> Ddbi_gen_base.scope)
    $ Pp.text ")"
    |> Pp.vgrp
    |> Ddbi_gen_base.scope

let print_t_of_item_field
  : Ddbi_field.t -> Pp.t =
  fun {name; field_type} ->
    Pp.text field_type
    $ Pp.text ".t_of_item ~name:\""
    $ Pp.text name
    $ Pp.text "\" item"
    $/ Pp.text ">>= fun "
    $ Pp.text name
    $ Pp.text " ->"
    $ Pp.break

let print_t_of_item
  : Ddbi_model.t -> Pp.t =
  fun {fields} ->
    Pp.text "let t_of_item ~name item ="
    $/ Pp.text "let open Result.Monad_infix in"
    $/ Pp.list ~sep:(Pp.text "") ~f:print_t_of_item_field fields
    $ (Pp.text "Ok {"
       $ Pp.list ~sep:(Pp.text ";" $ Pp.break) ~f:print_record_field fields
       $ Pp.text "}"
       |> Pp.fgrp)
    |> Pp.vgrp
    |> Ddbi_gen_base.scope

let print_get
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let get db id ="
    $/ (Pp.text "Ddbi.Common.get"
        $/ Pp.text "~db"
        $/ Pp.text "~id"
        $/ Pp.text "~t_of_item:(t_of_item ~name:\"\")"
        $/ Pp.text "~model_name"
        |> Ddbi_gen_base.scope
        |> Pp.fgrp)
    |> Pp.fgrp
    |> Ddbi_gen_base.scope

let print_put
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let put db t ="
    $/ (Pp.text "Ddbi.Common.put"
        $/ Pp.text "~db"
        $/ Pp.text "~t"
        $/ Pp.text "~item_of_t:(item_of_t ~name:\"\")"
        $/ Pp.text "~model_name"
        |> Ddbi_gen_base.scope
        |> Pp.fgrp)
    |> Pp.vgrp
    |> Ddbi_gen_base.scope

let print_make
  : Ddbi_model.t -> Pp.t =
  fun {fields} ->
    let base_fields = List.filter
        ~f:(fun {name} ->
            not (name = Ddbi_model.id_field_name) &&
            not (name = Ddbi_model.version_field_name))
        fields in
    let arg_printer {Ddbi_field.name} =
      Pp.text "~"
      $ Pp.text name in
    let printed_args =
      Pp.list ~sep:Pp.break ~f:arg_printer base_fields in
    (Pp.text "let make"
     $/ Pp.text "?("
     $// Pp.text Ddbi_model.id_field_name
     $// Pp.text "="
     $// Pp.text "Uuid.to_string (Uuid.create ()))"
     $/ printed_args
     $/ Pp.text "()"
     |> Pp.fgrp)
    $ Pp.text " ="
    $/ Pp.text "let _vsn = version in"
    $/ print_record fields
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_create_store
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let create_store db ="
    $/ (Pp.text "Ddbi.Common.create_store"
        $/ Pp.text "~db"
        $/ Pp.text "~model_name"
        $/ Pp.text "~indexes:[]"
        |> Pp.fgrp)
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let is_name
  : Ddbi_field.t -> Bool.t =
  fun {name; options} ->
    List.exists ~f:(fun op -> op = Ddbi_field.Name) options

let get_fields_in_name
  : Ddbi_model.t -> Ddbi_field.t List.t =
  fun {fields} ->
    List.filter ~f:is_name fields

let print_record_name
  : Ddbi_model.t -> Pp.t =
  fun model ->
    let name_fields = get_fields_in_name model in
    (Pp.text "let record_name "
     $ print_record name_fields
     $ Pp.text " ="
     |> Pp.vgrp)
    $/ (Pp.list
          ~sep:(Pp.break $ Pp.text "^" $ Pp.break)
          ~f:(fun {Ddbi_field.name} -> Pp.text name) name_fields
        |> Pp.fgrp)
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_file_of_t
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let file_of_t directory t ="
    $/ Pp.text "Ddbi.Common.file_of_t ~directory ~item:t"
    $/ (Pp.text "~item_converter:(fun tt ->"
        $/ (Pp.text "(record_name tt, sexp_of_t tt))"
            |> Ddbi_gen_base.scope)
        |> Ddbi_gen_base.scope
        |> Pp.vgrp)
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_t_of_file
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let t_of_file path ="
    $/ (Pp.text "Ddbi.Common.t_of_file"
        $/ Pp.text "~path"
        $/ Pp.text "~item_converter:t_of_sexp"
        |> Pp.fgrp)
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_foreign_model
  : Ddbi_model.foreign_model -> Pp.t =
  fun {name; model} ->
    ((Pp.text "let"
      $/ Pp.text name
      |> Pp.hgrp)
     $/ Pp.text "db"
     $/ Pp.text "t"
     $/ Pp.text "="
     |> Pp.fgrp)
    $/ (Pp.text model
        $ Pp.text ".get"
        $/ Pp.text "db"
        $/ Pp.text "t."
        $ Pp.text @@ name ^ "_id"
        |> Pp.fgrp)
    $/ (Pp.text ">>=? fun (db', item) ->"
        $/ Pp.text "match item with"
        $/ (Pp.text "| Some item ->"
            $/ Pp.text "return @@ Ok (db', item)"
            |> Ddbi_gen_base.scope
            |> Pp.fgrp)
        $/ (Pp.text "| None ->"
            $/ Pp.text "return @@ Error"
            $/ Pp.text "(Ddbi.Error"
            $/ Pp.text "(Ddbi.Unable_to_get "
            $/ Pp.text "\"model does not contain "
            $ Pp.text name
            $ Pp.text "\"))"
            |> Ddbi_gen_base.scope
            |> Pp.fgrp)
        |> Ddbi_gen_base.scope)
    |> Ddbi_gen_base.scope


let print_foreign_models
  : Ddbi_model.t -> Pp.t =
  fun model ->
    Pp.list ~sep:(Pp.break) ~f:print_foreign_model model.foreign_models
    |> Pp.vgrp

let print_all
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let all db ="
    $/ Pp.text "Ddbi.Common.all ~db ~t_of_item:(t_of_item ~name:\"\") ~model_name"
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_to_string
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let to_string t ="
    $/ Pp.text "Ddbi.Common.to_string ~converter:sexp_of_t t"
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let print_of_string
  : Unit.t -> Pp.t =
  fun () ->
    Pp.text "let of_string str ="
    $/ Pp.text "Ddbi.Common.of_string ~converter:t_of_sexp str"
    |> Ddbi_gen_base.scope
    |> Pp.vgrp

let generate
  : Ddbi_model.t -> Pp.t =
  fun model ->
    Ddbi_gen_base.print_header ()
    $ Pp.break
    $/ Ddbi_gen_base.print_record model
    $/ print_name model
    $ Pp.break
    $/ print_version model
    $ Pp.break
    $/ print_item_of_t model
    $ Pp.break
    $/ print_t_of_item model
    $ Pp.break
    $/ print_get ()
    $ Pp.break
    $/ print_put ()
    $ Pp.break
    $/ print_make model
    $ Pp.break
    $/ print_create_store ()
    $ Pp.break
    $/ print_record_name model
    $ Pp.break
    $/ print_file_of_t ()
    $ Pp.break
    $/ print_t_of_file ()
    $ Pp.break
    $/ print_all ()
    $ Pp.break
    $/ print_foreign_models model
    $ Pp.break
    $/ print_to_string ()
    $ Pp.break
    $/ print_of_string ()
    $ Pp.break
    |> Pp.vgrp
