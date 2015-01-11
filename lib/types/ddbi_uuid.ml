open Core.Std

type t = String.t with sexp

let make () =
  Uuid.to_string (Uuid.create ())

let name = "uuid"

let item_of_t: name:String.t -> t -> Aws_async.Dynamodb.attribute List.t =
  fun ~name id ->
    [(name, Aws_async.Dynamodb.string id)]

let t_of_item: name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t =
  fun ~name item ->
    let open Result.Monad_infix in
    Aws_async.Dynamodb.get_string name item

let to_string: t -> String.t =
  fun t ->
    Sexp.to_string @@ sexp_of_t t

let of_string: String.t -> t =
  fun str ->
    t_of_sexp @@ Sexp.of_string str
