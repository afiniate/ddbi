open Core.Std
open Async.Std

type t

module Infix:
sig
  val to_dynamodb: t -> Aws_async.Dynamodb.t
  val (!!): t -> Aws_async.Dynamodb.t
  val to_ddbi: Aws_async.Dynamodb.t -> t
end

type error_code =
  | Unable_to_read of String.t * String.t
  | Unable_to_write of String.t * String.t
  | Invalid_field of String.t
  | Unable_to_get of String.t with sexp

exception Error of error_code with sexp

val t_of_credentials: ?url:String.t -> access_id:String.t ->
  secret_key:String.t -> region:String.t -> t

val t_of_role: ?url:String.t -> role:String.t -> (t, Exn.t) Deferred.Result.t
