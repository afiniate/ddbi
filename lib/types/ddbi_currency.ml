open Core.Std

type iso_code =
  | USD (* United States Dollar *)  with sexp

type t = {version: Int.t;
          value: Int.t;
          iso_code: iso_code} with sexp

let current_version = 1

let name = "currency"

let make: iso_code:iso_code -> subunit:Int.t -> Unit.t -> t =
  fun ~iso_code ~subunit () ->
    {version=current_version; value=subunit; iso_code}

let string_of_iso_code: iso_code -> String.t =
  function
  | USD -> "USD"

let iso_code_of_string: String.t -> (iso_code, Exn.t) Result.t =
  let open Result.Monad_infix in
  function
  | "USD" -> Ok USD
  | _ -> Error (Ddbi_common.Error (Ddbi_common.Invalid_result, "iso"))

let item_of_t: name:String.t -> t -> Aws_async.Dynamodb.item =
  fun ~name {version; value; iso_code} ->
    Ddbi_common.prefix_item ~prefix:name
      ~item:[("version", Aws_async.Dynamodb.int version);
             ("value", Aws_async.Dynamodb.int value);
             ("iso", Aws_async.Dynamodb.string @@ string_of_iso_code iso_code)]

let t_of_item: name:String.t -> Aws_async.Dynamodb.item -> (t, Exn.t) Result.t =
  fun ~name item ->
    let open Result.Monad_infix in
    Aws_async.Dynamodb.get_int (Ddbi_common.make_name ~prefix:name ~name:"value") item
    >>= fun value ->
    Aws_async.Dynamodb.get_int (Ddbi_common.make_name ~prefix:name ~name:"version") item
    >>= fun version ->
    Aws_async.Dynamodb.get_string (Ddbi_common.make_name ~prefix:name ~name:"iso") item
    >>= iso_code_of_string
    >>= fun iso_code ->
    Ok {version; value; iso_code}

let to_smallest_subunit: t -> Int.t =
  fun t ->
    t.value

let to_main_unit: t -> Float.t =
  fun t ->
    (Float.of_int t.value) /. 100.0

let iso_code: t -> iso_code =
  fun {iso_code} ->
    iso_code

let add: t -> t -> (t, Exn.t) Result.t =
  fun t1 t2 ->
    if not (t1.iso_code = t2.iso_code)
    then Error (Ddbi_common.Error (Ddbi_common.Invalid_result, "Iso codes do not match"))
    else Ok {version=current_version; iso_code=t1.iso_code; value=t1.value + t2.value}

let to_string: t -> String.t =
  fun t ->
    Sexp.to_string @@ sexp_of_t t

let of_string: String.t -> t =
    fun str ->
      t_of_sexp @@ Sexp.of_string str
