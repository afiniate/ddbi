open Ocamlbuild_plugin;;

Options.use_ocamlfind := true;;

module Ddbi = struct
  let cmd = "lib/ddbi_exec.native"
  let run_ddbi dst suffix env _ =
    let dir = Filename.dirname (env dst) in
    let fname = (env "%.ddbi") in
    match suffix with
    | None ->
      Cmd (S [A cmd; A "--output"; Px dir; Px fname])
    | Some suf ->
      Cmd (S [A cmd; A "--suffix"; A suf; A "--output"; Px dir; Px fname])

  let rules () =
    rule "%.ddbi -> %.ml{i}" ~prods:["%.ml";"%.mli"] ~dep:"%.ddbi"
      (run_ddbi "%.ddbi" None);
    rule "%.ddbi -> %_raw.ml{i}" ~prods:["%_raw.ml";"%_raw.mli"] ~dep:"%.ddbi"
      (run_ddbi "%.ddbi" (Some "_raw"));
end;;

dispatch begin function
  | After_rules ->
    Ddbi.rules ()
  | _ -> ()
end
