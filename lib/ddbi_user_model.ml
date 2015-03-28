open Core.Std
open Async.Std

type options =
  | Name with sexp

type field_type =
  | ForeignModel of String.t
  | Type of String.t with sexp

type  = {name: String.t;
          field_type: field_type;
          options: options sexp_list} with sexp

type t = {name: String.t;
          version: Int.t;
          indexes: String.t sexp_list;
          fields: Ddbi_field.t List.t;
          foriegn_models: foreign_model sexp_list} with sexp

let id_field_name = "_id"
let version_field_name = "_vsn"

let add_system_fields
  : t -> t =
  fun model ->
    let {fields} = model in
    let new_fields =
      {Ddbi_field.name=id_field_name; field_type=Ddbi_field.Type "Ddbi.Types.Uuid";
       options=[Ddbi_field.Name]}
      ::{name=version_field_name;  field_type=Type "Ddbi.Types.Int"; options=[]}
      ::fields in
    {model with fields=new_fields}

let convert_field
  : Ddbi_field.t List.t * foreign_model List.t ->
    Ddbi_field.t ->
    Ddbi_field.t List.t * foreign_model List.t =
    fun (fields, foreigns) field ->
      match field.field_type with
      | Ddbi_field.ForeignModel model_name ->
        ({field with name=field.name ^ "_id"; field_type=(Type "Ddbi.Uuid")}::fields,
         {name=field.name; model=model_name}::foreigns)
      | _ ->
        (field::fields, foreigns)

let convert
  : t -> t =
  fun model ->
    let {fields} = model in
    let (new_fields, foreigns) = List.fold ~init:([], []) ~f:convert_field fields in
    {model with fields=new_fields; foriegn_models=foreigns}

let prepare
  : t -> t =
  fun model ->
    convert model
