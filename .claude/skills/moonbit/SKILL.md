---
name: moonbit
description: How to write MoonBit in html-sandbox — the moon.mod / moon.pkg DSL, which libraries are allowed and at which versions, how to discover APIs from source instead of guessing, code and test conventions, the Workers/Wasm ABI rules, and the checks to run before committing. Use whenever you write, edit, review, or plan MoonBit code (`.mbt`, `moon.mod`, `moon.pkg`) or anything under `moonbit/`, including CLI tools and scripts written in MoonBit, adding a dependency, or porting the Go blog to MoonBit — even if the request does not say "MoonBit" and only names a file or a TODO.md step.
---

# MoonBit in html-sandbox

The MoonBit code lives in `moonbit/` (module `podhmo/blog`): `site` renders
pages and is what the tests cover, `worker` is the Wasm entry point,
`workers/` is the Cloudflare Worker around it. `moonbit/README.md` and
`docs/sketch/ja/moonbit-workers-wasm.md` explain why things are the way
they are; read them before changing the ABI or the build.

MoonBit moves fast, and much of what you remember about it — and some of
the docs the toolchain itself ships — is out of date. The rules below are
mostly about **checking against the installed toolchain and the exact
library sources** rather than writing from memory.

## Toolchain and config format

- `moon version` is 0.1.20260920 at the time of writing. Configuration
  uses the **DSL files `moon.mod` and `moon.pkg`**, not `moon.mod.json` /
  `moon.pkg.json`. `~/.moon/AGENTS.md` and the `AGENTS.md` that `moon new`
  writes still describe the JSON format; ignore those parts.
- For language reference, read the official agent guide, which is up to
  date with the DSL:
  `~/ghq/github.com/moonbitlang/moonbit-agent-guide/moonbit-agent-guide/SKILL.md`
  (and its `references/`). Read the relevant section rather than the whole
  file; it is long.

The DSL shapes used here (all verified to build):

```
// moon.mod
name = "podhmo/blog"
version = "0.1.0"
preferred_target = "wasm-gc"

import {
  "moonbitlang/async@0.22.4",   // dependencies live here, always with a version
}
```

```
// moon.pkg of a library package
import {
  "podhmo/blog/site",
  "moonbitlang/core/argparse",  // core packages other than the prelude need importing too
}

supported_targets = "+wasm-gc"  // only build this package for wasm-gc

options(
  link: { "wasm-gc": { "exports": [ "path_push", "serve" ] } },
  targets: { "native_only.mbt": ["native"] },   // per-file conditional compilation
)
```

```
// moon.pkg of an executable
import { "moonbitlang/async", "moonbitlang/async/stdio" }
supported_targets = "+native"
pkgtype(kind: "executable")
```

An empty `moon.pkg` is a valid package. Run `moon fmt` after editing these
files; it normalizes them.

## Libraries

Use only `moonbitlang/core` (always available), `moonbitlang/x`, and
`moonbitlang/async`. Anything else from mooncakes needs the user's
go-ahead, because the point of `moonbit/` is to compare Wasm sizes and
every dependency muddies that.

`async`'s I/O is native-only (wasm-gc is unsupported), so it cannot go in
the Worker. It is for **CLI tools** (comparison scripts, generators) that
run on the developer's machine; see "CLI tools" below.

### Choosing a version

1. `moon update` first — a stale registry index resolves to old versions.
2. `moon add moonbitlang/<name>` picks the newest version, which may need
   a newer `moon` than the one installed. Example: async 0.22.5 fails on
   moon 0.1.20260920 with `Unexpected key 'max_concurrent_tests' found in
   moon.pkg`; 0.22.4 works. If the newest fails like that, pin the newest
   tag that builds and say so in the commit message. Upgrading the
   toolchain (`moon upgrade`) affects everything else in the repo, so ask
   the user before doing that.
3. Whatever version ends up in `moon.mod`, line up the reference clones
   with it (next section).

## Discovering APIs

Do not guess names or signatures — confirm them, in this order:

1. **`moon ide`** inside `moonbit/` — exact for core and for this
   module's own code, because both come with the installed toolchain:
   - `moon ide doc StringBuilder`, `moon ide doc "@argparse.Command"` —
     exported API and docs (`moon doc <symbol>` is deprecated)
   - `moon ide peek-def Array::length` — the definition with source
   - `moon ide outline <file-or-dir>`, `moon ide hover --loc f.mbt:L:C`

   **Not for x and async.** For dependencies, `moon ide doc` answers from
   the registry's symbol index, which can be a different version than the
   one pinned: with async@0.22.4 in `moon.mod` it printed
   `// moonbitlang/async@0.21.3`. Check the version in its first line, and
   use the sources (step 2) for x and async.
2. **The library sources, at the version you build against.** Run
   `.claude/skills/moonbit/scripts/sync-refs.sh` (reads the versions in
   `moonbit/moon.mod`; or pass `async@0.22.4` to look at a candidate).
   It clones/fetches `~/ghq/github.com/moonbitlang/{x,async}` and checks out
   the tag `v<version>`, so the source you read is the source you compile.
   Then:
   - `core`: read `~/.moon/lib/core` — the copy shipped with the toolchain,
     which is exactly what compiles. The `core` clone has no tags; use it
     only for `git log`.
   - Public API per package: `src/<pkg>/pkg.generated.mbti` in async,
     `<pkg>/pkg.generated.mbti` in core and x.
   - Usage examples: the package's `*_test.mbt`, and for async,
     `examples/` (`cat`, `xargs`, `curl`, `http_file_server`, ...).
3. **Hard-won notes**: `~/ghq/github.com/podhmo/moonbit-individual-handbook/docs/knowledge.md`
   records surprises found by actually running things (where stdin lives,
   deprecated APIs, target differences). The ones that matter most here
   are in [references/pitfalls.md](references/pitfalls.md).
4. Diagnostics: `moon explain --diagnostic <code>`.

Docs and memory lose to the toolchain whenever they disagree; if a fact
matters, try it in a scratch module under `/tmp/go-html-sandbox/`.

## Writing code

Follow what `moonbit/site/site.mbt` and `moonbit/worker/worker.mbt` do:

- Start every top-level item with `///|`. Tools split files on it.
- Doc comments are English sentences that start with the item's name, Go
  style: `/// render answers the request for path: ...`. Comment the
  why, not the what, and keep the density of the surrounding code.
- Functions are private unless another package needs them; `pub(all)`
  only when other packages must construct the type.
- Build strings with `StringBuilder` (characters). `Buffer` is for bytes;
  mixing the two garbles non-ASCII text.
- Deprecations you will otherwise write from memory: `derive(Show)` (use
  `derive(Debug)`; on a `pub` type that warns `implicit_impl_as_method`,
  so read the warning's suggested fix), `Iterator` (use `Iter`),
  `StringView::to_string` (use `to_owned()`), `try?`.
- Treat warnings as things to fix, not noise: `moon check` reports them,
  and `moon explain --diagnostic <code>` explains them.

### Packages and tests

- Tests are blackbox files `<pkg>_test.mbt` next to the code, calling the
  package qualified (`@site.render(...)`); unqualified calls warn.
- Keep logic in library packages and keep executables thin (`cmd/` or a
  `pkgtype(kind: "executable")` package with only `main`). `_test.mbt`
  files in an executable package warn that main packages will stop
  generating blackbox tests.
- Anything that imports host functions (`fn put(code : Int) = "host" "put"`)
  stays in `worker`. A test binary that contains such an import cannot run,
  which is why `site` and `worker` are separate.

## Workers and Wasm

- Target **wasm-gc without `use-js-builtin-string`**. Workers compile
  imported Wasm without the JS string builtins, so that option breaks at
  instantiate time.
- Strings cross the boundary one UTF-16 code unit at a time: the path in
  through the exported `path_push`, the response out through the imported
  `host.status`, `host.put`, `host.header_name`, `host.header_value`.
  Extend the response by adding to `site.Response`, not by adding imports;
  if a new import is truly needed, change `worker/worker.mbt`,
  `workers/worker.mjs`, `moonbit/README.md`, and the research notes
  together.
- New exports go in `worker/moon.pkg`'s `link` block. After changing the
  boundary, confirm the built Wasm exports and imports only what you
  intend (e.g. `WebAssembly.Module.exports/imports` in Node).
- Adding a package that the Worker uses? Add its directory to
  `build.watch_dir` in `workers/wrangler.jsonc`, or `make dev` will not
  rebuild when it changes.
- Embedding files: there is no `go:embed`. `moon.pkg` supports pre-build
  commands (`:embed`); check the agent guide's `references/advanced-moonbit-build.md`
  for the current DSL syntax before relying on it.
- Size is the experiment's metric. Note the Wasm size
  (`make build` prints it) when a change could move it, and record it in
  `docs/` when the step asks for it. `wasm-opt` is not in the build; if you
  measure with it, pass explicit `--enable-*` flags (see the research notes)
  — `-all` produces Wasm that V8 cannot load.

## CLI tools

Helper tools in MoonBit (e.g. the Go-vs-MoonBit comparison script, or an
embed generator) are native executables built on `moonbitlang/async`:

```moonbit
///|
async fn main {
  let matches = @argparse.Command(
    "hello",
    positionals=[PositionArg("name", num_args=ValueRange(lower=0))],
  ).parse()
  let name = match matches.values {
    { "name": [n, ..], .. } => n
    _ => "world"
  }
  @stdio.stdout.write("hello, \{name}\n")
}
```

- Model them on `async/examples/` **at the pinned tag**, not on memory:
  `cat` (argparse + stdin/stdout + files), `xargs` (processes), `curl`
  (HTTP client), `http_file_server`.
- stdin/stdout live in `moonbitlang/async/stdio`; core and x only have
  `println`/`eprintln`. `@stdio.stdin.read_all().text()` reads all input.
- They can live inside `moonbit/` beside the Worker: give the tool's
  package `supported_targets = "+native"` and `worker` `supported_targets
  = "+wasm-gc"` (its host imports do not compile natively). Then plain
  `moon check` / `moon test` / the wasm-gc build skip the tool and keep the
  Wasm unchanged, and `moon check --target native` and
  `moon run --target native <pkg> -- args` work too. Add a Makefile target
  for the tool rather than asking people to remember the flags.

## Before committing

From `moonbit/`, run `make check` (`moon fmt --check`, `moon check`,
`moon test`) and make it pass; if you touched a native-only package, also
`moon check --target native`. If the change affects what the Worker
serves, try it with `make dev` (`make dev PORT=8798` if 8787 is taken by
the Go Worker). Then follow the repo's usual rules: English commit
messages prefixed with `moonbit:`, TODO.md updated through the `todo-md`
skill, and findings recorded in `docs/sketch/ja/moonbit-workers-wasm.md`
(Japanese).
