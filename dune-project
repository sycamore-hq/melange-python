(lang dune 3.21)

(using directory-targets 0.1)

(name melange_python)

(package
 (name melange_python)
 (synopsis "OCaml-to-Python compiler backend built on Melange")
 (depends
  ocaml
  dune
  melange
  cmdliner
  cppo
  dune-build-info
  ppxlib
  menhir))
