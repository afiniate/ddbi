open Core.Std
open Async.Std

type option =
  | Name with sexp

type options = option List.t with sexp

type t = {name: String.t;
          field_type: String.t;
          options: options} with sexp
