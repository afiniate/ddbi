open Core.Std
open Async.Std

let load
  : String.t -> Ddbi_model.t Deferred.t =
  fun file ->
    match Ddbi_parser.parse @@ Sexp.load_sexp file with
    | Ok model ->
      return model
    | Error (Ddbi_parser.ParseError response_fun) ->
      print_string @@ response_fun ();
      exit 1
    | Error _ ->
      print_string "Unexpected error encountered while parsing";
      exit 1

let do_gen log_level output_dir suffix input_file () =
  load input_file
  >>= fun model ->
  Ddbi.Generator.generate ~dir:output_dir ~suffix model
  >>| fun _ -> ()

let regular_file =
  Command.Spec.Arg_type.create
    (fun filename ->
       match Core.Std.Sys.is_file filename with
       | `Yes -> filename
       | `No | `Unknown ->
         eprintf "'%s' is not a regular file.\n%!" filename;
         Pervasives.exit 1)

let regular_dir =
  Command.Spec.Arg_type.create
    (fun dirname ->
       match Core.Std.Sys.is_directory dirname with
       | `Yes -> dirname
       | `No | `Unknown ->
         eprintf "'%s' is not a regular directory.\n%!" dirname;
         Pervasives.exit 1)

let log_level =
  Command.Spec.Arg_type.create
    (function
      | "v" -> "error"
      | "vv" -> "info"
      | "vvv" -> "debug"
      | value ->
        eprintf "'%s' is not a log level. Log levels are in the form v | vv | vvv" value;
        Pervasives.exit 1)

let spec =
  let open Command.Spec in
  empty
  +> flag ~aliases:["-l"] "--log-level" (optional_with_default "v" log_level)
    ~doc:"log-level The log level to set"
  +> flag ~aliases:["-o"] "--output" (required regular_dir)
    ~doc:"output The directory in which to write the modules"
  +> flag ~aliases:["-s"] "--suffix" (optional string)
    ~doc:"suffix The suffix of the module name. For when you want the module to be fronted"
  +> anon ("filename" %: regular_file)

let readme () =
  "You must provide a file in the DDBI format, given that file the system will \
   generate well defined interface files into the directory specified by `--output`."

let command =
  Command.async_basic ~summary:"Generate dynamodb interface files based on provided parameters"
    ~readme
    spec
    do_gen

let () =
  Command.run ~version:"1.0" ~build_info:"" command
