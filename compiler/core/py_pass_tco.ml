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
