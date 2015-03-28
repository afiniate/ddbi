open Core.Std
open Core_extended.Std
open Async.Std

let width = 80

let create_base_name
  : suffix:String.t Option.t -> ext:String.t -> Ddbi_model.t -> String.t =
  fun ~suffix ~ext {name} ->
    match suffix with
    | Some value ->  name ^ "_" ^ value ^ "." ^ ext
    | None -> name ^ "." ^ ext

let create_name
  : dir:String.t -> suffix:String.t Option.t -> ext:String.t -> Ddbi_model.t -> String.t =
  fun ~dir ~suffix ~ext model ->
    Filename.implode [dir; create_base_name ~suffix ~ext model]

let generate_ml
  : dir:String.t -> suffix:String.t Option.t -> Ddbi_model.t -> Unit.t Deferred.t =
  fun ~dir ~suffix model ->
    let ml_name = create_name dir suffix "ml" model in
    let contents = Pp.to_string ~width @@ Ddbi_ml.generate model in
    Writer.save ml_name ~contents

let generate_mli
  : dir:String.t -> suffix:String.t Option.t -> Ddbi_model.t -> Unit.t Deferred.t =
  fun ~dir ~suffix model ->
    let mli_name = create_name dir suffix "mli" model in
    let contents = Pp.to_string ~width @@ Ddbi_mli.generate model in
    Writer.save mli_name ~contents

let generate
  : dir:String.t -> suffix:String.t Option.t -> Ddbi_model.t -> Unit.t Deferred.t =
  fun ~dir ~suffix raw_model ->
    let model = Ddbi_model.prepare raw_model in
    generate_ml ~dir ~suffix model
      >>= fun _ ->
    generate_mli ~dir ~suffix model
    >>| fun _ -> ()
