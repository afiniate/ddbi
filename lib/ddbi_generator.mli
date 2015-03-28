open Core.Std
open Core_extended.Std
open Async.Std

val generate: dir:String.t -> suffix:String.t Option.t ->
  Ddbi_model.t -> Unit.t Deferred.t
