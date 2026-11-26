# Melange Python

An OCaml-to-Python compiler backend built on [Melange](https://melange.re/).

Melange's frontend is kept as-is through optimized Lam. A new backend then lowers Lam to a Python IR, runs tail-call and scope passes, and prints one `.py` file per OCaml module:

```
.ml / .re
  -> parse / PPX / typemod
  -> Translmod + Lambda_simplif
  -> Lam_convert + Lam passes
  -> Lam_coercion (grouped Lam)
       `-- Python: lam_compile_python -> Py IR -> TCO/scope passes -> py_dump -> .py
```

The first milestone is a Dune build of `print_endline "hello"` that produces a `.py` file and prints `hello` under Python 3.12+.

License: MIT.
