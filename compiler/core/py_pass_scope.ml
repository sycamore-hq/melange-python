(* Rename identifiers that clash with Python keywords. *)

let is_keyword = function
  | "False" | "None" | "True" | "and" | "as" | "assert" | "async" | "await"
  | "break" | "case" | "class" | "continue" | "def" | "del" | "elif" | "else"
  | "except" | "finally" | "for" | "from" | "global" | "if" | "import" | "in"
  | "is" | "lambda" | "match" | "nonlocal" | "not" | "or" | "pass" | "raise"
  | "return" | "try" | "type" | "while" | "with" | "yield" ->
      true
  | _ -> false

let rename name = if is_keyword name then name ^ "_" else name

let rec map_expr = function
  | Py.Name name -> Py.Name (rename name)
  | Py.Call (fn, args) -> Py.Call (map_expr fn, List.map map_expr args)
  | Py.Runtime (fn, args) -> Py.Runtime (fn, List.map map_expr args)
  | (Py.Unit | Py.Bool _ | Py.Int _ | Py.Num _ | Py.Str _) as expr -> expr

let rec map_stmt = function
  | Py.Assign (name, expr) -> Py.Assign (rename name, map_expr expr)
  | Py.Expr expr -> Py.Expr (map_expr expr)
  | Py.Return expr -> Py.Return (map_expr expr)
  | Py.Function { name; params; body } ->
      Py.Function
        {
          name = rename name;
          params = List.map rename params;
          body = List.map map_stmt body;
        }
  | Py.If (cond, then_, else_) ->
      Py.If (map_expr cond, List.map map_stmt then_, List.map map_stmt else_)
  | Py.While { test; body } ->
      Py.While { test = map_expr test; body = List.map map_stmt body }
  | Py.Pass -> Py.Pass

let apply program = List.map map_stmt program
