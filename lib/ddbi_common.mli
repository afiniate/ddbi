open Core.Std
open Async.Std
open Deferred.Result.Monad_infix

type error_code =
  | Invalid_result with sexp

exception Error of error_code * String.t with sexp

type 'a t_of_item = Aws_async.Dynamodb.item -> ('a, Exn.t) Result.t
type 'a item_of_t = 'a -> Aws_async.Dynamodb.item

val get: db:Ddbi_system.t ->
  id:Ddbi_uuid.t ->
  t_of_item:'a t_of_item ->
  model_name:String.t ->
  (Ddbi_system.t * 'a Option.t, Exn.t) Deferred.Result.t

val all: db:Ddbi_system.t -> t_of_item:'a t_of_item ->
  model_name:String.t -> (Ddbi_system.t * 'a List.t, Exn.t) Deferred.Result.t

val put: db:Ddbi_system.t -> t:'a -> item_of_t:'a item_of_t ->
  model_name:String.t -> (Ddbi_system.t, Exn.t) Deferred.Result.t

type index_desc

val describe_index: ?read_capacity_units:Int.t -> ?write_capacity_units:Int.t ->
  name:String.t -> key:String.t ->
  key_type:Aws_async.Dynamodb.Base_t.attribute_type -> Unit.t ->
  index_desc
(** Create a simple global secondary index on a single key with read
    and write capacity preset *)

val create_store: db:Ddbi_system.t -> model_name:String.t ->
  indexes:index_desc List.t -> (Ddbi_system.t, Exn.t) Deferred.Result.t

val convert_all: db:Aws_async.Dynamodb.t -> items:Aws_async.Dynamodb.item List.t ->
  t_of_item:'a t_of_item -> (Ddbi_system.t * 'a List.t, Exn.t) Deferred.Result.t

val file_of_t: directory:String.t -> item:'a -> item_converter:('a -> String.t * Sexp.t) ->
  (Unit.t, Exn.t) Deferred.Result.t
(**
 * Given an item, a directory and a function that takes that item and returns both the
 * file name and the file contents, write it the result to that file
*)

val t_of_file: path:String.t -> item_converter:(Sexp.t -> 'a) -> ('a, Exn.t) Deferred.Result.t
(**
 * Given a file name take the file and read the contents, passing it
 *  to the provided function returning that function
*)

val to_string: converter:('a -> Sexp.t) -> 'a -> String.t
(** Convert the type to a string *)

val of_string: converter:(Sexp.t -> 'a) -> String.t -> 'a
(** Convert a previously formatted string to a type *)

val make_name: ?prefix:String.t -> name:String.t -> String.t
(**
 * make a valid named given a prefix and a name
*)

val prefix_item: ?prefix:String.t -> item:Aws_async.Dynamodb.item -> Aws_async.Dynamodb.item
(**
 * Apply the prefix to all the item names
*)
