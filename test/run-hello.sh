#!/bin/sh
# M1 exit test: dune build produces hello.py, and python3 runs it.
set -eu
cd "$(dirname "$0")/.."
python3 -c 'import sys; assert sys.version_info >= (3, 12), sys.version'
dune build test/hello/dist/hello.py
artifact=_build/default/test/hello/dist/hello.py
out=$(python3 "$artifact")
test "$out" = hello
printf 'ok: python3 %s\n' "$artifact"
