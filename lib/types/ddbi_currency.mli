open Core.Std

(**
 * This represents currency. The currencies supported are enumerated in the
 * iso_code type. It should not be used to represent currencies not in that type.
*)
type iso_code =
  | USD (* United States Dollar *) with sexp

type t with sexp

include Ddbi_type.Type with type t := t

val make: iso_code:iso_code -> subunit:Int.t -> Unit.t -> t
(**
 * Make a new currency value with an iso code and value in the smallest
 * subunit of the specified currency
*)

val to_smallest_subunit: t -> Int.t
(**
 * Return the currency as the smallest subunit in the specified currency.
 * For USD and EUR this will be cents, for PEN this will be centimos, etc.
*)

val to_main_unit: t -> Float.t
(**
 * Return the value as the main unit of currency as a float. For
 * USD this will be dollars, for EUR this will be euros, for PEN, sols etc
 * This is a convenience. Remember the inherent inaccuracy of floats
 * and the potential problems of managing currency as floats.
*)

val iso_code: t -> iso_code

val string_of_iso_code: iso_code -> String.t
val iso_code_of_string: String.t -> (iso_code, Exn.t) Result.t

val add: t -> t -> (t, Exn.t) Result.t
(** Add the values of two currencies together to produce the aggregate result
    as a third currency *)
