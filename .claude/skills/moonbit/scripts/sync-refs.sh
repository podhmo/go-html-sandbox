#!/bin/sh
# sync-refs.sh lines the reference clones under ~/ghq/github.com/moonbitlang
# up with what moonbit/ builds against, so reading their source shows the
# API that will actually compile.
#
#   sync-refs.sh                 # the versions imported in moonbit/moon.mod
#   sync-refs.sh async@0.22.4    # a version you are considering adding
#
# x and async are checked out at the tag v<version> (detached HEAD; the
# clones are read-only references). moonbit-docs is tagged with moonc's
# version: it is checked out at that tag, or at origin/main while the
# tag does not exist yet (main is then the docs for the newest release).
# core cannot be lined up: the toolchain ships a commit that is not in the
# public repository, so read its own copy in ~/.moon/lib/core; the clone
# is only fetched, for `git log`. The agent guide has no tags and is pulled.
set -eu

ROOT=${GHQ_ROOT:-$HOME/ghq}/github.com/moonbitlang
MOD=$(git rev-parse --show-toplevel 2>/dev/null || pwd)/moonbit/moon.mod

clone() { # clone name: clone moonbitlang/<name> if it is missing, then fetch
  if [ ! -d "$ROOT/$1" ]; then
    git clone -q "https://github.com/moonbitlang/$1.git" "$ROOT/$1"
  fi
  git -C "$ROOT/$1" fetch -q --tags origin
}

if [ $# -eq 0 ] && [ -f "$MOD" ]; then
  # Lines like `  "moonbitlang/async@0.22.4",` in the import block.
  set -- $(sed -n 's/^[[:space:]]*"moonbitlang\/\([a-z_]*@[0-9][^"]*\)".*/\1/p' "$MOD")
fi

for dep in "$@"; do
  name=${dep%@*}
  version=${dep#*@}
  case $name in
  x | async) ;;
  *) echo "skip $dep: only moonbitlang/x and moonbitlang/async are pinned here" >&2; continue ;;
  esac
  clone "$name"
  git -C "$ROOT/$name" -c advice.detachedHead=false checkout -q "v$version"
  echo "$name: v$version at $ROOT/$name"
done

clone core
echo "core: read ~/.moon/lib/core ($(sed -n 's/^version = "\(.*\)"/\1/p' "$HOME/.moon/lib/core/moon.mod"), shipped with $(moon version | head -1))"

# `moonc v0.10.15+943464bfa (2026-10-12) ...` -> v0.10.15
moonc=$(moon version --all | sed -n 's/^moonc \(v[0-9.]*\).*/\1/p')
clone moonbit-docs
if git -C "$ROOT/moonbit-docs" rev-parse -q --verify "refs/tags/$moonc" >/dev/null; then
  git -C "$ROOT/moonbit-docs" -c advice.detachedHead=false checkout -q "$moonc"
  echo "moonbit-docs: $moonc at $ROOT/moonbit-docs"
else
  git -C "$ROOT/moonbit-docs" -c advice.detachedHead=false checkout -q --detach origin/main
  echo "moonbit-docs: no tag $moonc yet; origin/main ($(git -C "$ROOT/moonbit-docs" log -1 --format=%cs)) at $ROOT/moonbit-docs"
fi

clone moonbit-agent-guide
git -C "$ROOT/moonbit-agent-guide" -c advice.detachedHead=false checkout -q --detach origin/HEAD
echo "moonbit-agent-guide: origin/HEAD ($(git -C "$ROOT/moonbit-agent-guide" log -1 --format=%cs)); no tags, may lag the toolchain"
