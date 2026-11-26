(* Lower grouped Lam to Python.
   M1 knows constants, lets, sequences, module blocks, and the
   `console.log` external that Melange's Stdlib uses for [print_endline]. *)

open Import

module Ffi = Melange_ffi.External_ffi_types.External_spec

let unsupported lam =
  let buf = Buffer.create 128 in
  let fmt = Format.formatter_of_buffer buf in
  Format.fprintf fmt
    "melpy: this Lam is not lowered by the M1 Python backend:@\n%a@."
    Lam_print.lambda lam;
  failwith (Buffer.contents buf)

let unsupported_prim primitive =
  let buf = Buffer.create 64 in
  let fmt = Format.formatter_of_buffer buf in
  Format.fprintf fmt
    "melpy: primitive not lowered by the M1 Python backend: %a@."
    Lam_print.primitive primitive;
  failwith (Buffer.contents buf)

let py_ident id =
  let raw = Ident.name id ^ "_" ^ string_of_int (Ident.stamp id) in
  let buf = Buffer.create (String.length raw) in
  String.iter raw ~f:(fun c ->
      match c with
      | 'a' .. 'z' | 'A' .. 'Z' | '0' .. '9' | '_' -> Buffer.add_char buf c
      | _ -> Buffer.add_char buf '_');
  match Buffer.contents buf with
  | "" -> "mel_id"
  | s when s.[0] >= '0' && s.[0] <= '9' -> "_" ^ s
  | s -> s

let effect_of expr =
  match expr with
  | Py.Call _ | Py.Runtime _ -> [ Py.Expr expr ]
  | _ -> []

let const = function
  | Lam.Constant.Const_string { s; _ } | Lam.Constant.Const_pointer s -> Py.Str s
  | Lam.Constant.Const_int { i; _ } -> Py.Int (Int32.to_int i)
  | Lam.Constant.Const_char c -> Py.Int (Char.code c)
  | Lam.Constant.Const_float lit -> Py.Num lit
  | Lam.Constant.Const_int64 i -> Py.Num (Int64.to_string i)
  | Lam.Constant.Const_js_true -> Py.Bool true
  | Lam.Constant.Const_js_false -> Py.Bool false
  | Lam.Constant.Const_js_null
  | Lam.Constant.Const_js_undefined _
  | Lam.Constant.Const_module_alias
  | Lam.Constant.Const_block _
  | Lam.Constant.Const_float_array _
  | Lam.Constant.Const_some _ ->
      Py.Unit

let console_log = function
  | Ffi.Js_call { name = "log"; scopes; _ } | Ffi.Js_send { name = "log"; scopes; _ }
    ->
      List.exists scopes ~f:(fun scope -> scope = "console")
  | _ -> false

let rec lower_expr lam =
  match lam with
  | Lam.Lvar id | Lam.Lmutvar id -> ([], Py.Name (py_ident id))
  | Lam.Lglobal_module _ -> ([], Py.Unit)
  | Lam.Lconst constant -> ([], const constant)
  | Lam.Llet (_, id, rhs, body) -> bind id rhs body
  | Lam.Lmutlet (id, rhs, body) -> bind id rhs body
  | Lam.Lsequence (first, second) ->
      let pre, first_expr = lower_expr first in
      let post, second_expr = lower_expr second in
      (pre @ effect_of first_expr @ post, second_expr)
  | Lam.Lifused (_, body) -> lower_expr body
  | Lam.Lprim { primitive; args; _ } -> lower_prim primitive args
  | Lam.Lapply _ | Lam.Lfunction _ | Lam.Lletrec _ | Lam.Lswitch _
  | Lam.Lstringswitch _ | Lam.Lstaticraise _ | Lam.Lstaticcatch _
  | Lam.Ltrywith _ | Lam.Lifthenelse _ | Lam.Lwhile _ | Lam.Lfor _
  | Lam.Lassign _ | Lam.Lsend _ ->
      unsupported lam

and bind id rhs body =
  let pre, rhs_expr = lower_expr rhs in
  let post, body_expr = lower_expr body in
  if Lam_hit.hit_variable id body then
    (pre @ [ Py.Assign (py_ident id, rhs_expr) ] @ post, body_expr)
  else (pre @ effect_of rhs_expr @ post, body_expr)

and lower_args args =
  match args with
  | [] -> ([], [])
  | arg :: rest ->
      let stmts, expr = lower_expr arg in
      let rest_stmts, rest_exprs = lower_args rest in
      (stmts @ rest_stmts, expr :: rest_exprs)

and lower_prim primitive args =
  match primitive with
  | Lam_primitive.Pjs_call { ffi; _ } when console_log ffi ->
      let stmts, exprs = lower_args args in
      (stmts, Py.Runtime ("print_endline", exprs))
  | Lam_primitive.Pccall { prim_name = "log" } ->
      let stmts, exprs = lower_args args in
      (stmts, Py.Runtime ("print_endline", exprs))
  | Lam_primitive.Pmakeblock _ ->
      let stmts, _exprs = lower_args args in
      (stmts, Py.Unit)
  | _ -> unsupported_prim primitive

let lower_stmts lam =
  let stmts, expr = lower_expr lam in
  stmts @ effect_of expr

let lower_group = function
  | Lam_group.Nop lam -> lower_stmts lam
  | Lam_group.Single (_, id, rhs) ->
      let stmts, expr = lower_expr rhs in
      stmts @ [ Py.Assign (py_ident id, expr) ]
  | Lam_group.Recursive _ ->
      failwith
        "melpy: recursive bindings are not lowered by the M1 Python backend"

let dump_groups groups =
  match Sys.getenv_opt "MELPY_DUMP_LAM" with
  | Some "1" ->
      List.iter groups ~f:(fun group ->
          Format.eprintf "%a@." Lam_group.pp_group group)
  | _ -> ()

let emit ~output_prefix groups =
  dump_groups groups;
  let program = List.concat (List.map groups ~f:lower_group) in
  let program =
    match program with
    | [] ->
        failwith "melpy: Python backend produced an empty module"
    | program -> program
  in
  let program = Py_pass_scope.apply program in
  let program = Py_pass_tco.apply program in
  if not !Clflags.dont_write_files then
    Py_dump.write (output_prefix ^ ".py") program
