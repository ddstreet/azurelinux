#!/bin/bash

set -eux

pkg-config --cflags augeas
pkg-config --libs augeas

src_dump="$(realpath source/examples/dump.c)"

tmpdir="$(mktemp -d)"
pushd "$tmpdir"

gcc -o dump $(pkg-config --cflags --libs augeas) "$src_dump"
test -x dump
./dump > /dev/null

popd
rm -rf "$tmpdir"
