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

(* Rewrite self tail calls to assignments inside `while True`.
   Mutual recursion is left for a later milestone. *)

let temps args =
  let rec loop i acc = function
    | [] -> List.rev acc
    | arg :: rest ->
        loop (i + 1) ((Printf.sprintf "_tco_%d" i, arg) :: acc) rest
  in
  loop 0 [] args

let rec rewrite_tail ~self ~params stmts =
  match List.rev stmts with
  | Py.Return (Py.Call (Py.Name name, args)) :: rev_prefix
    when name = self && List.length args = List.length params ->
      let prefix = List.rev rev_prefix in
      let temps = temps args in
      let binds = List.map (fun (tmp, arg) -> Py.Assign (tmp, arg)) temps in
      let sets =
        List.map2 (fun param (tmp, _) -> Py.Assign (param, Py.Name tmp)) params temps
      in
      (prefix @ binds @ sets, true)
  | Py.If (cond, then_, else_) :: rev_prefix ->
      let then_, then_hit = rewrite_tail ~self ~params then_ in
      let else_, else_hit = rewrite_tail ~self ~params else_ in
      (List.rev rev_prefix @ [ Py.If (cond, then_, else_) ], then_hit || else_hit)
  | _ -> (stmts, false)

let maybe_loop name params body =
  match rewrite_tail ~self:name ~params body with
  | body, true -> [ Py.While { test = Py.Bool true; body } ]
  | body, false -> body

let rec map_stmt = function
  | Py.Function { name; params; body } ->
      let body = List.map map_stmt body in
      Py.Function { name; params; body = maybe_loop name params body }
  | Py.If (cond, then_, else_) ->
      Py.If (cond, List.map map_stmt then_, List.map map_stmt else_)
  | Py.While { test; body } ->
      Py.While { test; body = List.map map_stmt body }
  | (Py.Assign _ | Py.Expr _ | Py.Return _ | Py.Pass) as stmt -> stmt

let apply program = List.map map_stmt program
