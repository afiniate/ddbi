open Core.Std
open Result.Monad_infix
open Sexplib.Std

exception ParseError of ( Unit.t -> String.t ) with sexp

let convert_options: Sexp.t -> (Ddbi_field.options, Exn.t) Result.t =
  function
  | Sexp.List [Sexp.Atom "name"] ->
    Ok [Ddbi_field.Name]
  | Sexp.List [] ->
    Ok []
  | res ->
    Error (ParseError (fun () ->
        "Invalid option at " ^ (Sexp.to_string res)))

let convert_field
  : model:Ddbi_model.t -> name:String.t ->
  field_type:String.t -> Ddbi_field.options -> (Ddbi_model.t, Exn.t) Result.t =
  fun ~model ~name ~field_type options ->
    Ok {model with fields={Ddbi_field.name; field_type; options}::model.fields}

let convert_model_field
  : model:Ddbi_model.t -> name:String.t -> foreign_model:String.t ->
  (Ddbi_model.t, Exn.t) Result.t =
  fun ~model ~name ~foreign_model ->
    let {Ddbi_model.foreign_models} = model in
    convert_field ~model ~name:(name ^ "_id") ~field_type:"Ddbi.Types.Uuid" []
    >>| fun new_model ->
    {new_model with foreign_models = {name; model=foreign_model}::foreign_models }

let parse_field : Sexp.t -> model:Ddbi_model.t -> (Ddbi_model.t, Exn.t) Result.t =
  fun sexp ~model ->
    match sexp with
    | Sexp.List [Sexp.Atom name; Sexp.Atom "foreign-model"; Sexp.Atom foreign_model] ->
      convert_model_field model name foreign_model
    | Sexp.List [Sexp.Atom name; Sexp.Atom field_type] ->
      convert_field ~model ~name ~field_type []
    | Sexp.List [Sexp.Atom name; Sexp.Atom field_type; options] ->
      convert_options options
      >>= convert_field ~model ~name ~field_type
    | res ->
      Error (ParseError (fun () ->
          "Invalid option at " ^ (Sexp.to_string res)))

let rec fields : Sexp.t List.t -> model:Ddbi_model.t -> (Ddbi_model.t, Exn.t) Result.t =
  fun sexp_fields ~model ->
    match sexp_fields with
    | hd::tl ->
      parse_field hd model
      >>= fun new_model ->
      fields tl ~model:new_model
    | [] ->
      Ok model

let parse : Sexp.t -> (Ddbi_model.t, Exn.t) Result.t =
  function
  | Sexp.List ((Sexp.Atom "record")::(Sexp.Atom name)::(Sexp.Atom vsn)
               :: rest) ->
    fields rest {name; version=Int.of_string vsn; fields=[]; indexes=[]; foreign_models=[]}
  | res ->
    Error (ParseError (fun () ->
        "Invalid option at " ^ (Sexp.to_string res)))
