# Summary: TODO "Go 版のブログと比べる" (without the moonbit skill)

## What was done

Commit `1d11422` in the clone (`moonbit: add a CLI comparing the Go blog and the Worker path by path`):

- `moonbit/moon.mod`: added dependency `moonbitlang/async@0.22.5` (via `moon add moonbitlang/async@0.22.5`; the newest version in the local registry index, works with moon 0.1.20261012).
- `moonbit/compare/` (library package, all targets): `Fetched` (Ok(status, content_type, body) | Failed(msg)), `Result`, `default_paths`, `join_url`, `normalize` (replaces each server's own base URL with `{BASE_URL}` so the OGP tags do not differ by port alone), `compare`, `body_diff` (first differing line and column, shows ~100 chars of each side starting a little before the difference, because pages are long single lines), `report`.
- `moonbit/compare/compare_test.mbt`: 5 blackbox tests (join_url, normalize, matching responses, full report with status/content-type/body/request-failure, long-line excerpt).
- `moonbit/compare/cmd/` (executable, `supported_targets = "+native"`): argparse positionals `go`, `moonbit`, `paths...`; fetches with `@http.get` (does not follow redirects, so 307s are compared as is); prints the report; `fail`s (non-zero exit) when any path differs.
- `moonbit/worker/moon.pkg`: `supported_targets = "+wasm-gc"` so `moon check --target native` does not try to compile the host imports.
- `moonbit/Makefile`: `make compare` (`GO_URL` default http://localhost:8080, `MOONBIT_URL` default http://localhost:$(PORT), optional `PATHS`), and `make check` now also runs `moon check --target native`.
- `moonbit/README.md`: package list entry and a "Comparing with the Go blog" section.
- `TODO.md`: the step marked `[x]`, parent changed to `[-]` (per `.claude/skills/todo-md/SKILL.md`).

Default paths: `/`, `/posts/hello`, `/docs/ja/design`, `/docs/`, `/favicon.svg`, `/no-such-page`.

The Worker Wasm is unchanged: built `worker.wasm` at 62c287d (in a temporary git worktree, removed afterwards) and after the change; both 5279 bytes and `cmp` identical.

## Commands and results

`make check` (final):
```
moon fmt --check
Finished. moon: no work to do
moon check
Finished. moon: no work to do
moon test
Total tests: 7, passed: 7, failed: 0.
moon check --target native
Finished. moon: no work to do
```
Also `moon test --target native`: 7 passed (plus a harmless macOS libtool "table of contents is empty" warning for async's types lib).

Servers: `cd go && make generate && go run ./examples/blog -addr localhost:18111`, `cd moonbit && make dev PORT=18112`. Both stopped afterwards (verified no listeners on 18111/18112).

`make compare GO_URL=http://localhost:18111 PORT=18112` (all 6 differ, as the TODO expects at first):
```
DIFF  /
      body: 1637 vs 148 chars, 2 vs 2 lines; first difference at line 2
      ... (first run, before column excerpts were added)
DIFF  /posts/hello
      status: go 200, moonbit 404
      body: 1875 vs 180 chars, ...
DIFF  /docs/ja/design
      status: go 200, moonbit 404
      body: 5088 vs 183 chars, ...
DIFF  /docs/
      status: go 200, moonbit 404
      body: 1772 vs 174 chars, ...
DIFF  /favicon.svg
      status: go 200, moonbit 404
      content-type: go "image/svg+xml", moonbit "text/html; charset=utf-8"
      body: 248 vs 180 chars, ...
DIFF  /no-such-page
      body: 839 vs 181 chars, ...
6 of 6 paths differ
Failure(compare/cmd/main.mbt:58:5-58:30@podhmo/blog FAILED: some paths differ)
make: *** [compare] Error 1
```
With PATHS="/ /favicon.svg /docs /posts/hello.md" (final version, with column excerpts):
```
DIFF  /
      body: 1637 vs 148 chars, 2 vs 2 lines; first difference at line 2, column 16
      go:      "<html lang=\"ja\" data-theme=\"dark\"><head>...
      moonbit: "<html lang=\"ja\"><head><meta charset=\"utf-8\"><title>blog</title>...
DIFF  /favicon.svg   (status 200 vs 404, content-type image/svg+xml vs text/html)
DIFF  /docs          (status 307 vs 404)
DIFF  /posts/hello.md (status 200 vs 404, text/markdown vs text/html)
4 of 4 paths differ
```
Sanity checks: Go vs itself (`MOONBIT_URL=http://localhost:18111/`) -> "0 of 6 paths differ", exit 0. Unreachable server -> `moonbit: request failed: OSError("@socket.Tcp::connect(): Connection refused")`.

## Sources consulted

- Repo: `TODO.md`, `moonbit/{README.md,Makefile,moon.mod,site,worker,workers}`, `go/Makefile`, `go/examples/blog/main.go`, `go/examples/blog/internal/site/{server.go,docs.go,posts.go}`, `.claude/skills/todo-md/SKILL.md`.
- `moonbitlang/async@0.22.5` source unzipped from `~/.moon/registry/cache` into `/tmp/go-html-sandbox/asyncsrc`: `src/http/pkg.generated.mbti`, `src/http/request.mbt` (confirmed no redirect following), `src/io/pkg.generated.mbti`, `examples/curl`, `examples/xargs` (moon.pkg shape with `supported_targets = "+native"` and `pkgtype(kind: "executable")`).
- Core: `~/.moon/lib/core/argparse/pkg.generated.mbti`, `builtin/pkg.generated.mbti`.

## What went wrong / caveats

- **Accidental exposure to the moonbit skill**: the clone's working tree already had `.claude/skills/moonbit/*` deleted (unstaged, pre-existing). My first `git diff` (to see what `moon add` changed in moon.mod) printed those deletions, i.e. the full content of the moonbit SKILL.md and pitfalls.md, into my context. I did not open it deliberately. By that point I had already chosen async + a native-only package from the async examples; the one thing that matches the skill afterwards is putting `supported_targets = "+wasm-gc"` on `worker` (which I would also have needed for `moon check --target native` to pass). Treat this run as partly contaminated.
- Because of those pre-existing deletions, `diff.patch` (`git diff 62c287d` as instructed) also contains the deletion of the three `.claude/skills/moonbit/` files; they are not part of my commit.
- `moon check` warned about deprecated `StringView::to_string` (use `to_owned`) and `inspect` on non-Debug values; fixed.
- The non-zero exit prints MoonBit's `Failure(... FAILED: some paths differ)` line; there is no exit() in core/async, so `fail` is used.
- Normalization only replaces each server's own base URL, so comparing `localhost` vs `127.0.0.1` against the same Go server still differs in OGP tags (the Go server's base URL is `http://localhost:18111`). Expected.
- No docs/sketch note was added; the Worker's Wasm is unaffected.
