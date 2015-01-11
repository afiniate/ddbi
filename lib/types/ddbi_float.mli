open Core.Std

type t = Float.t with sexp

include Ddbi_type.Type with type t := t

val make: Float.t -> t
