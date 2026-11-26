(* Python IR for the Melange backend.
   A statement/expression subset, not the CPython AST: enough to print
   a module, bind names, branch, loop, and call the runtime. *)

type expr =
  | Unit
  | Bool of bool
  | Int of int
  | Num of string
  | Str of string
  | Name of string
  | Call of expr * expr list
  | Runtime of string * expr list

type stmt =
  | Assign of string * expr
  | Expr of expr
  | Return of expr
  | Function of { name : string; params : string list; body : stmt list }
  | If of expr * stmt list * stmt list
  | While of { test : expr; body : stmt list }
  | Pass

type program = stmt list
