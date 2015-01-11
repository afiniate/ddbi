open Core.Std
open Async.Std

type foreign_model = {name: String.t;
                      model: String.t} with sexp

type t = {name: String.t;
          version: Int.t;
          indexes: String.t sexp_list;
          fields: Ddbi_field.t List.t;
          foreign_models: foreign_model sexp_list} with sexp

val id_field_name: String.t
val version_field_name: String.t

val prepare: t -> t
