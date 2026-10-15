#!/bin/sh
# sync-refs.sh lines the reference clones under ~/ghq/github.com/moonbitlang
# up with what moonbit/ builds against, so reading their source shows the
# API that will actually compile.
#
#   sync-refs.sh                 # the versions imported in moonbit/moon.mod
#   sync-refs.sh async@0.22.4    # a version you are considering adding
#
# x and async are checked out at the tag v<version> (detached HEAD; the
# clones are read-only references). core has no tags: the toolchain ships
# its own copy in ~/.moon/lib/core, which is the exact source to read, so
# the core clone is only fetched, for `git log`. The agent guide is pulled.
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

if [ -d "$ROOT/moonbit-agent-guide" ]; then
  git -C "$ROOT/moonbit-agent-guide" pull -q --ff-only || echo "moonbit-agent-guide: pull failed; reading it as is" >&2
fi
