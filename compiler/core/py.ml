(* Copyright (C) 2026 Nathan Sculli
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program. If not, see
 * <https://www.gnu.org/licenses/>. *)

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
