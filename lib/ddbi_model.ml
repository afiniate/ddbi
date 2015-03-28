open Core.Std
open Async.Std

type foreign_model = {name: String.t;
                      model: String.t} with sexp

type t = {name: String.t;
          version: Int.t;
          indexes: String.t sexp_list;
          fields: Ddbi_field.t List.t;
          foreign_models: foreign_model sexp_list} with sexp

let id_field_name = "_id"
let version_field_name = "_vsn"

let add_system_fields
  : t -> t =
  fun model ->
    let {fields} = model in
    let new_fields =
      ({Ddbi_field.name=id_field_name; field_type="Ddbi.Types.Uuid"; options=[Ddbi_field.Name]}
      ::({name=version_field_name;  field_type="Ddbi.Types.Int"; options=[]}
      ::fields)) in
    {model with fields=new_fields}


let prepare
  : t -> t =
  fun model ->
    add_system_fields model
