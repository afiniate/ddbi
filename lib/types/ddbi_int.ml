open Core.Std

type t = Int.t with sexp

let make: Int.t -> t =
  ident

let name = "int"

let item_of_t
  : name:String.t -> t -> Aws_async.Dynamodb.attribute List.t =
  fun ~name value ->
    [(name, Aws_async.Dynamodb.int value)]

let t_of_item
  : name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t =
  fun ~name item ->
    let open Result.Monad_infix in
    Aws_async.Dynamodb.get_int name item

let to_string: t -> String.t =
  Ddbi_common.to_string ~converter:sexp_of_t

let of_string: String.t -> t =
  Ddbi_common.of_string ~converter:t_of_sexp
