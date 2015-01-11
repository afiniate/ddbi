DDBI - DynamoDB Interface Generator
===================================

This is an interface generator for interfacing with Dynamodb via
[Aws_async](https://github.com/afiniate/aws_async). Essentially, you
define a record in a ddbi file using lispish sexpressions and call the
`ddbi` command on that file.

## Defining Records

Records are defined with the follking syntax


    field-name = <ocaml valid field name>
    field-type = <ocaml valid module name>
    option = 'name'
    model-name = <ocaml valid module name>

    record_definition = '(' , <field-name> , <field-type> , ')'
                      | '(' , <field-name> , <field-type> , '(' , { <option> } , ')' , ')'
                      | '(' , <field-name> , 'foreign-model' , <model-name> , ')'

     record = '(' , 'record' , <name> , <vsn> ,
                  { <record-definition> } , ')'

An example of the above syntax can be found below.

    (record test_record 2
        (foo Ddbi.Types.Int)
        (foo2 Ddbi.Types.Float)
        (bar Ddbi.Types.String)
        (baz Ddbi.Types.String (name))
        (back Test_record_embedded)
        (book foreign-model Test_record_dependency))

All of the field names must be valid ocaml field names, as do each of
the module names. The version is used to help upgrade/downgrade from
versions in the database.

You can treat any generated model as a type and embed it. If its
embedded as a regular field type then the record is literally emedded
in the parent record. If you declare it as a foreign-model then the
record is stored in a seperate table and only the id for it is stored
locally.

### Built In Types

* Currency - Ddbi.Types.Int
* Float - Ddbi.Types.Float
* Int - Ddbi.Types.Int
* String - Ddbi.Types.String
* Uuid - Ddbi.Types.Uuid

These are somewhat obvious as to their purpose.

### Hand Rolled Types

You can create a type manually just fine. You just have to include `Ddbi.Type`

## Addition Functionality to the Record

It is recommeded that you generate the record with a `_raw.ml{i}` name
then enclude that record in the record that provides the additional
functionality. That is the most straight forward way to add
functionality to a ddbi record.

## Running the ddbi command

    ddbi [--suffix <suffix> --output <dir>] <ddbi-name>


### Running the command from ocamlbuild

```
open Ocamlbuild_plugin;;

Options.use_ocamlfind := true;;

module Ddbi = struct
  let cmd = "ddbi"
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
```
