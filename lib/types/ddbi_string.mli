open Core.Std

type t = String.t with sexp

include Ddbi_type.Type with type t := t

val make: String.t -> t
