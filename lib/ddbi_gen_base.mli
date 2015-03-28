open Core.Std
open Core_extended.Std

val default_indent: Int.t

val scope: Pp.t -> Pp.t
val newline: Pp.t
val expr: Pp.t -> Pp.t
val print_field_type: String.t -> Pp.t
val print_field: Ddbi_field.t -> Pp.t
val record_field_sep: Pp.t
val print_fields: Ddbi_field.t List.t -> Pp.t
val print_record: Ddbi_model.t -> Pp.t
val print_header: Unit.t -> Pp.t
