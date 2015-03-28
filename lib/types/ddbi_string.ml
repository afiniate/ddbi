open Core.Std

type t = String.t with sexp

let make: String.t -> t =
  ident

let name = "String"

let item_of_t
  : name:String.t -> t -> Aws_async.Dynamodb.attribute List.t =
  fun ~name value ->
    [(name, Aws_async.Dynamodb.string value)]

let t_of_item
  : name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t =
  fun ~name item ->
    let open Result.Monad_infix in
    Aws_async.Dynamodb.get_string name item


let to_string: t -> String.t =
  ident

let of_string: String.t -> t =
  ident
