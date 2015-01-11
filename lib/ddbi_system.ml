open Core.Std
open Async.Std

type t = Aws_async.Dynamodb.t

module Infix =
struct
  let to_dynamodb t = t
  let (!!) = to_dynamodb
  let to_ddbi t = t
end

type error_code =
  | Unable_to_read of String.t * String.t
  | Unable_to_write of String.t * String.t
  | Invalid_field of String.t
  | Unable_to_get of String.t with sexp

exception Error of error_code with sexp

let t_of_credentials
  : ?url:String.t -> access_id:String.t -> secret_key:String.t -> region:String.t -> t =
  fun ?url ~access_id ~secret_key ~region ->
  Aws_async.Dynamodb.t_of_credentials ?url access_id secret_key region

let t_of_role
  : ?url:String.t -> role:String.t -> (t, Exn.t) Deferred.Result.t =
  fun ?url ~role ->
    Aws_async.Dynamodb.t_of_role ?url role
