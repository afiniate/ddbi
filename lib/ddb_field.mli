open Core.Std
open Async.Std

type t = {name: String.t;
          field_type: field_type} with sexp
