# ADR 0001: Repository layout and licensing

## Status

Accepted. Nathan Sculli decided the mixed license for this repository: `compiler/` under LGPL-2.1-or-later, and the runtime and tooling under MIT.

## Context

The repository started under the MIT License. Melange is LGPL-2.1-or-later (the identifier in its `dune-project`). Vendored Melange sources also keep their own copyright headers, which grant LGPL version 3 or any later version plus Melange's additional linking permission. Those headers cannot be replaced.

A separate `sycamore-hq/melange` repository, included as a submodule, was the other layout. This repository keeps the compiler in-tree so the Python backend changes stay in one review.

The in-flight M1 tree is not a full Melange checkout. It vendors Melange's driver and `jscomp/core` from release 7.0.1-53 (commit `ddc1436070616766f45e5000b7822c7156c36515`) and links the installed Melange 7.0.1-53 libraries. Later issues that say `compiler/jscomp/...` mean the corresponding path under `compiler/` here.

## Decision

| Path | What it is | License |
| --- | --- | --- |
| `compiler/` | Vendored Melange compiler, Python backend modifications, and compiler build glue | LGPL-2.1-or-later |
| `compiler/LICENSE` | GNU LGPL version 2.1 text | the license text itself |
| `compiler/COPYING` | GPL-3 text shipped with Melange | upstream text, kept |
| `compiler/COPYING.LESSER` | LGPL-3 text shipped with Melange | upstream text, kept |
| `runtime/` | Handwritten Python package `melange_runtime` | MIT |
| `test/` | Hello program, Dune rule, and `test/run-hello.sh` | MIT |
| `docs/` | This ADR and later docs | MIT |
| `dune`, `dune-project`, `README.md` | Root tooling and project docs | MIT |
| `LICENSE` | MIT text for the runtime and tooling | MIT |

New compiler sources written here carry a copyright header for Nathan Sculli and LGPL-2.1-or-later. That includes `compiler/core/py.ml`, `py_dump.ml`, `py_pass_scope.ml`, `py_pass_tco.ml`, `lam_compile_python.ml`, `git_commit.ml`, and `compiler/gen_cmi_flags.sh`.

Upstream copyright headers on vendored and modified Melange files stay as they were.

Issue writeups that use a different path apply to this tree as follows:

- `compiler/jscomp/core/` is `compiler/core/`.
- `runtime/python/melange_runtime/` is `runtime/melange_runtime/`.
- `examples/hello/` is `test/hello/`.

## Consequences

A binary that links the compiler with the MIT runtime is a combined work. The compiler portion stays under the LGPL. The runtime and tooling stay MIT when distributed on their own.

`compiler/COPYING` and `compiler/COPYING.LESSER` remain because vendored headers refer to LGPL version 3 or later, which the "or later" option of LGPL-2.1 permits.
