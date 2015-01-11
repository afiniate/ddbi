open Core.Std
open Async.Std
open Deferred.Result.Monad_infix
open Ddbi_system.Infix

type error_code =
  | Invalid_result with sexp

type index_desc = String.t *
                  Aws_async.Dynamodb.Base_t.attribute_type *
                  Aws_async.Dynamodb.Base_t.global_secondary_index

exception Error of error_code * String.t with sexp

type 'a t_of_item = Aws_async.Dynamodb.item -> ('a, Exn.t) Result.t
type 'a item_of_t = 'a -> Aws_async.Dynamodb.item

let get
  : db:Ddbi_system.t -> id:Ddbi_uuid.t -> t_of_item:'a t_of_item ->
  model_name:String.t -> (Ddbi_system.t * 'a Option.t, Exn.t) Deferred.Result.t =
  fun ~db ~id ~t_of_item ~model_name ->
    Aws_async.Dynamodb.Getitem.exec !!db model_name
    @@ (Ddbi_uuid.item_of_t Ddbi_model.id_field_name id)
    >>= function
    | (db', {Aws_async.Dynamodb.Getitem_t.item = Some item}) ->
      let open Result.Monad_infix in
      Deferred.return @@ (t_of_item item
                          >>= fun item ->
                          Ok (to_ddbi db', Some item))
    | (db', {Aws_async.Dynamodb.Getitem_t.item = None}) ->
      return @@ Ok (to_ddbi db', None)

let convert_all
  : db:Aws_async.Dynamodb.t -> items:Aws_async.Dynamodb.item List.t ->
  t_of_item:'a t_of_item -> (Ddbi_system.t * 'a List.t, Exn.t) Deferred.Result.t =
  fun ~db ~items ~t_of_item ->
    let get_result () =
      let open Result.Monad_infix in
      Result.all (List.map ~f:t_of_item items)
      >>= fun converted_items ->
      Ok (to_ddbi db, converted_items) in
    return @@ get_result ()

let all
  : db:Ddbi_system.t -> t_of_item:'a t_of_item -> model_name:String.t ->
  (Ddbi_system.t * 'a List.t, Exn.t) Deferred.Result.t =
  fun ~db ~t_of_item ~model_name ->
    Aws_async.Dynamodb.Scan.all !!db model_name
    >>= fun (db', {Aws_async.Dynamodb.Scan_t.items=items}) ->
    convert_all db' items t_of_item

let put
  : db:Ddbi_system.t -> t:'a -> item_of_t:'a item_of_t ->
  model_name:String.t -> (Ddbi_system.t, Exn.t) Deferred.Result.t =
  fun ~db ~t ~item_of_t ~model_name ->
    let item = item_of_t t in
    Aws_async.Dynamodb.Putitem.exec !!db model_name item
    >>| fun (db', _) -> to_ddbi db'

let describe_index
  : ?read_capacity_units:Int.t -> ?write_capacity_units:Int.t ->
    name:String.t -> key:String.t ->
    key_type:Aws_async.Dynamodb.Base_t.attribute_type -> Unit.t ->
    index_desc =
  fun ?(read_capacity_units = 1) ?(write_capacity_units = 1)
    ~name ~key ~key_type () ->
    (key, key_type,
     {Aws_async.Dynamodb.Base_t.gsi_name = name;
      gsi_key_schema = [{schema_name = key;
                         key_type = `HASH}];
      gsi_projection = {non_key_attributes = None;
                        projection_type = `ALL};
      gsi_provisioned_throughput = {read_capacity_units;
                                    write_capacity_units}})

let create_store
  : db:Ddbi_system.t ->
  model_name:String.t ->
  indexes:index_desc List.t ->
  (Ddbi_system.t, Exn.t) Deferred.Result.t =
  fun ~db ~model_name ~indexes ->
    let open Aws_async.Dynamodb.Base_t in
    let global_secondary_indexes =
      Some (List.map indexes
              ~f:(fun (_, _, index) -> index)) in
    let attribute_definitions =
      ({attr_name = "uuid";
        attr_type = `S}
       ::List.map indexes
         ~f:(fun (attr_name, attr_type, _) ->
             {attr_name; attr_type})) in
    let table = {Aws_async.Dynamodb.Createtable_t.name = model_name;
                 attribute_definitions;
                 global_secondary_indexes;
                 key_schema = [{schema_name = "uuid";
                                key_type = `HASH}];
                 local_secondary_indexes = None;
                 provisioned_throughput = {read_capacity_units = 1;
                                           write_capacity_units = 1}} in
    Aws_async.Dynamodb.Createtable.exec !!db table
    >>| fun (db', _) -> to_ddbi db'

let file_of_t
  : directory:String.t -> item:'a -> item_converter:('a -> String.t * Sexp.t) ->
  (Unit.t, Exn.t) Deferred.Result.t =
  fun ~directory ~item ~item_converter ->
    let (filename, sexp_contents) = item_converter item in
    let path = directory ^ "/" ^ filename ^ ".scm" in
    try
      let open Deferred in
      Writer.save path ~contents:(Sexp.to_string sexp_contents)
      >>= fun _ ->
      return @@ Ok ()
    with exn ->
      return @@ Result.Error (Ddbi_system.Error (Ddbi_system.Unable_to_write
                                                   (path, Exn.to_string exn)))

let t_of_file
  : path:String.t -> item_converter:(Sexp.t -> 'a) -> ('a, Exn.t) Deferred.Result.t =
  fun ~path ~item_converter ->
    try
      let contents = Sexp.load_sexp path in
      return @@ Ok (item_converter contents)
    with exn ->
      return @@ Result.Error (Ddbi_system.Error
                                (Ddbi_system.Unable_to_read (path, Exn.to_string exn)))

let make_name'
  : prefix:String.t -> name:String.t -> String.t =
    fun ~prefix ~name ->
      prefix ^ "_" ^ name

let make_name
  : ?prefix:String.t -> name:String.t -> String.t =
  fun ?prefix ~name ->
    match prefix with
    | Some pre ->
      make_name' pre name
    | None ->
      name

let prefix_item
  : ?prefix:String.t -> item:Aws_async.Dynamodb.item -> Aws_async.Dynamodb.item =
  fun ?prefix ~item ->
    match prefix with
    | Some pre ->
      List.map ~f:(fun (name, value) ->
          (make_name' ~prefix:pre ~name, value)) item
    | None ->
      item

let to_string: converter:('a -> Sexp.t) -> 'a -> String.t =
  fun ~converter t ->
    Sexp.to_string @@ converter t

let of_string: converter:(Sexp.t -> 'a) -> String.t -> 'a =
  fun ~converter str ->
    converter @@ Sexp.of_string str
