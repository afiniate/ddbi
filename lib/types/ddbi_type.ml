open Core.Std
open Async.Std


module type Type =
sig
  type t with sexp
  include Stringable with type t := t
  val name: String.t
  val item_of_t: name:String.t -> t -> Aws_async.Dynamodb.attribute List.t
  val t_of_item: name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t
end
