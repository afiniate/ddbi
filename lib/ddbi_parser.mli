open Core.Std

exception ParseError of ( Unit.t -> String.t ) with sexp

val parse: Sexp.t -> (Ddbi_model.t, Exn.t) Result.t
