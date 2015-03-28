open Core.Std

type t = Float.t with sexp

let make: Float.t -> t =
  ident

let name = "float"

let item_of_t
  : name:String.t -> t -> Aws_async.Dynamodb.attribute List.t =
  fun ~name value ->
    [(name, Aws_async.Dynamodb.float value)]

let t_of_item
  : name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t =
  fun ~name item ->
    let open Result.Monad_infix in
    Aws_async.Dynamodb.get_float name item

let to_string: t -> String.t =
  fun t ->
    Sexp.to_string @@ sexp_of_t t

let of_string: String.t -> t =
  fun str ->
    t_of_sexp @@ Sexp.of_string str
