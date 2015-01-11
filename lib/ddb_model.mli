open Core.Std
open Async.Std

type field_type =
  | Binary
  | String
  | Float
  | Int
  | Complex of String.t
  | C of String.t with sexp

type model = {model_name: String.t;
              version: Int.t;
              indexes: String.t List.t;
              fields: field List.t} with sexp
