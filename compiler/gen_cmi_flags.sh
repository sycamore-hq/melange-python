#!/bin/sh
# Write a dune flags sexp that exposes Melange's installed private cmis.
set -eu
out=$1
if ! command -v ocamlfind >/dev/null 2>&1; then
  echo "ocamlfind is required to locate the installed melange libraries" >&2
  exit 1
fi
{
  printf '('
  for pkg in \
    melange.__private__.melange_compiler_libs \
    melange.__private__.melstd \
    melange.__private__.melange_ffi \
    melange.__private__.pp
  do
    root=$(ocamlfind query "$pkg")
    printf ' -I %s/.public_cmi' "$root"
  done
  printf ' )\n'
} > "$out"
