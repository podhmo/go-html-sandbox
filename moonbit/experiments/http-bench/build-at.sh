#!/bin/sh
# usage: sh build-at.sh <commit> <name>
# Builds the blog's Wasm at <commit> in a temporary git worktree and copies
# it to build/<name>.wasm, so the adapters of other commits can be timed
# against the current one.
set -eu
commit=$1
name=$2
here=$(cd "$(dirname "$0")" && pwd)
tree=$(mktemp -d)
trap 'git -C "$here" worktree remove --force "$tree"' EXIT
git -C "$here" worktree add --detach -q "$tree" "$commit"
make -C "$tree/moonbit" build >/dev/null
mkdir -p "$here/build"
# The Worker's directory was workers/ before it became cloudflare/.
for dir in cloudflare workers; do
  if [ -f "$tree/moonbit/$dir/build/app.wasm" ]; then
    cp "$tree/moonbit/$dir/build/app.wasm" "$here/build/$name.wasm"
    break
  fi
done
ls -l "$here/build/$name.wasm"
