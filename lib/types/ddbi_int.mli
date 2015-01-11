open Core.Std

type t = Int.t with sexp

include Ddbi_type.Type with type t := t

val make: Int.t -> t
