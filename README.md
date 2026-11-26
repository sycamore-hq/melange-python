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

Milestone 1 compiles that program with `melpy --target python`. The driver is Melange 7.0.1-53 (OCaml 5.3) through grouped Lam. A Python IR, a keyword-scope pass, and a self-tail-call pass sit in front of the `.py` printer. The JavaScript backend is still in the tree and is not used for `--target python`.

The OCaml 5.3 / Melange 7.0.1-53 pin matches the compiler libraries this backend links. Later milestones can move the same cut to Melange main.

```sh
dune build test/hello/dist/hello.py
python3 _build/default/test/hello/dist/hello.py
```

`test/run-hello.sh` runs those commands and checks that the output is `hello`. Python 3.12 or newer is required. The Dune rule copies `melange_runtime` next to the artifact so `python3` can import it.

## Licensing

This repository uses two licenses.

- `compiler/` is GNU LGPL-2.1-or-later. It holds the vendored Melange compiler and every modification of that compiler, including the Python backend. Upstream copyright headers stay on those files. The LGPL text is [`compiler/LICENSE`](compiler/LICENSE). [`compiler/COPYING`](compiler/COPYING) and [`compiler/COPYING.LESSER`](compiler/COPYING.LESSER) are the GPL-3 and LGPL-3 texts shipped with Melange.
- The runtime and tooling are MIT, under the root [`LICENSE`](LICENSE). That covers `runtime/`, `test/`, the root Dune files, and docs. Copyright (c) 2026 Nathan Sculli.

The directory map is in [`docs/adr/0001-repo-layout-and-licensing.md`](docs/adr/0001-repo-layout-and-licensing.md).
