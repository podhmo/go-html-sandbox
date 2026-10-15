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

- **Stay on the latest toolchain**; no version is pinned. Before MoonBit
  work, compare `moon version` with the latest release:

  ```sh
  curl -fsSL https://cli.moonbitlang.com/version.json   # "moon" item
  ```

  If it is behind, ask the user to run `! moon upgrade` (it prompts, so it
  cannot run without a terminal). Then run `make check` in `moonbit/`;
  releases change the language, and `moon fmt` rewrites the sources to
  match. Commit that reformat on its own, before your change.
- Configuration uses the **DSL files `moon.mod` and `moon.pkg`**, not
  `moon.mod.json` / `moon.pkg.json`. `~/.moon/AGENTS.md` and the
  `AGENTS.md` that `moon new` writes still describe the JSON format;
  ignore those parts.
- First run `.claude/skills/moonbit/scripts/sync-refs.sh`. It lines the
  reference clones under `~/ghq/github.com/moonbitlang/` up with what you
  build against: x and async at the tags in `moonbit/moon.mod`,
  moonbit-docs at the tag of `moonc`'s version (or its main while that
  tag does not exist yet). Reading a clone at another version shows APIs
  and syntax that may not compile.
- For language and config reference, read the official docs at that
  version: `moonbit-docs/next/toolchain/moon/{module,package}.md` for
  `moon.mod` / `moon.pkg`, `next/language/` for the language. The agent
  guide (`moonbit-agent-guide/moonbit-agent-guide/SKILL.md`) is shorter
  and written for agents, but it has no tags and can lag the toolchain;
  when it disagrees with the docs, the docs win.

The DSL shapes used here (all verified to build):

```
// moon.mod
name = "podhmo/blog"
version = "0.1.0"
preferred_target = "wasm-gc"

import {
  "moonbitlang/async@0.22.5",   // dependencies live here, always with a version
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

An empty `moon.pkg` is a valid package.

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
2. `moon add moonbitlang/<name>` picks the newest version, which can need
   a newer `moon` than the one installed (it then fails to read the
   library's `moon.pkg`, e.g. `Unexpected key ... found in moon.pkg`).
   Upgrade the toolchain (see above) rather than pinning an older library.
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
   one pinned: with async@0.22.5 in `moon.mod` (after `moon update`) it
   printed `// moonbitlang/async@0.21.3`. Check the version in its first line, and
   use the sources (step 2) for x and async.
2. **The library sources, at the version you build against.** After
   `sync-refs.sh` (pass `async@<version>` for a library you are about to
   add, since it is not in `moon.mod` yet), the clone's checkout is the
   source you compile; confirm with `git -C <clone> describe --tags`
   before trusting what you read.
   - `core`: read `~/.moon/lib/core`, the copy shipped with the toolchain.
     The shipped commit is not in the public repository, so the `core`
     clone cannot be lined up; use it only for `git log`.
   - Public API per package: `src/<pkg>/pkg.generated.mbti` in async,
     `<pkg>/pkg.generated.mbti` in core and x.
   - Usage examples: the package's `*_test.mbt`, and for async,
     `examples/` (`cat`, `xargs`, `curl`, `http_file_server`, ...).
3. **Hard-won notes**: `~/ghq/github.com/podhmo/moonbit-individual-handbook/docs/knowledge.md`
   records surprises found by actually running things (where stdin lives,
   target differences), on the moon of its time — re-check before relying
   on an entry. The ones that matter most here are in
   [references/pitfalls.md](references/pitfalls.md).
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
- Leave formatting, deprecations, and other things `make check` reports
  to the tools: write, run `make check`, and fix what it says
  (`moon explain --diagnostic <code>` explains a warning).

### Packages and tests

- Tests are blackbox files `<pkg>_test.mbt` next to the code, calling the
  package qualified (`@site.render(...)`).
- Keep logic in library packages and keep executables thin (`cmd/` or a
  `pkgtype(kind: "executable")` package with only `main`), so the tests
  live in the library package.
- Anything that imports host functions (`fn put(code : Int32) = "host" "put"`)
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
- Generated sources (e.g. embedding files; there is no `go:embed`): keep
  them out of git, and make plain `moon check` / `moon test` work in a
  fresh clone, not only `make` — editors and agents run moon directly.
  `moon.pkg`'s `rule(...)` + `dev_build(rule:, input:, output:)` runs a
  generator before moon builds the package. Its paths are relative to the
  package directory while the command runs in the module root, and a
  directory as `input` reruns only when files are added or removed, not
  edited — so have `make` run the generator too. Read
  `moonbit-docs/next/toolchain/moon/package.md` for the syntax.
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
the Go Worker). Stop only the processes you started, by PID (or the
`make dev` job you launched); the user usually has their own
`wrangler dev` running, and `pkill -f workerd` / `pkill wrangler` kill it. Then follow the repo's usual rules: English commit
messages prefixed with `moonbit:`, TODO.md updated through the `todo-md`
skill, and findings recorded in `docs/sketch/ja/moonbit-workers-wasm.md`
(Japanese).
