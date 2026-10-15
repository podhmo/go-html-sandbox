# Embed go/examples/blog/posts/*.md for MoonBit (with skill)

## What was done

Committed as `6ad7ab7 moonbit: embed the Go blog's posts as (file name, content) pairs` (not pushed).

- New package `moonbit/posts`:
  - `moon.pkg`: `rule(name: "embed-md", command: "sh scripts/embed.sh $output $input")` and
    `dev_build(rule: "embed-md", input: "../../go/examples/blog/posts", output: "embedded.mbt")`.
  - generated `posts/embedded.mbt` (git-ignored) exposes
    `pub let files : ReadOnlyArray[(String, String)]`: (file name such as `2026-10-14-hello.md`, content),
    sorted by name, like Go's `posts.FS`.
  - `posts_test.mbt`: checks that all four current posts are present and sorted, that content is whole (prefix and suffix), and that non-ASCII text is intact.
- `moonbit/scripts/embed.sh OUT DIR`: POSIX sh. For each `DIR/*.md` (LC_ALL=C order) it runs
  `moon tool embed --text` (what `:embed` uses) and builds the array. It writes OUT only if the content changed.
- `moonbit/Makefile`: new `embed` target; `build`, `test`, `check` depend on it; `clean` removes embedded.mbt.
- `moonbit/workers/wrangler.jsonc`: build command now `cd .. && make build && ...`; `watch_dir` adds
  `../../go/examples/blog/posts` (not `../posts`, since the build writes there).
- `moonbit/.gitignore`: `posts/embedded.mbt`.
- Docs: `moonbit/README.md` (posts package, embed behavior), `docs/sketch/ja/moonbit-workers-wasm.md`
  (replaced the "未確認のこと" entry with a "記事の埋め込み" section), `TODO.md` (embed item split into
  `[x] 記事` / `[ ] 文書`, parent `[-]`), skill: `references/pitfalls.md` (String::compare is shortlex),
  `SKILL.md` (embedding bullet now points to `posts/` and the dev_build facts below).

## Findings (verified on moon 0.1.20261012 / moonc v0.10.15, which is the latest release)

- `dev_build` input/output paths resolve relative to the **package directory**, not the module root as
  the docs say. The command runs in the module root and gets `$input` as `./../go/...`.
  Output outside the package dir gives a warning and is not compiled.
- `input` accepts an array. A glob (`*.md`) is not expanded (fails as "missing").
- A directory as `input` reruns only when the directory mtime changes (add/remove), not on edits to a file.
  So make also runs the script each time (write-if-changed, so no spurious rebuilds).
- `String::compare` / `Array::sort` on strings is length-first. My first sort test failed when a shorter
  file name was added. Fixed with `sort_by((a, b) => a.lexical_compare(b))`.
- The Worker does not import `posts` yet, so worker.wasm stays 5,279 B. Probe (reverted): having `site` write
  one post gave 15,687 B, and editing a post then `make build` put the edit into the Wasm.

## Commands and results

- `moon version --all` = latest from `cli.moonbitlang.com/version.json` (0.1.20261012); no upgrade needed.
- `.claude/skills/moonbit/scripts/sync-refs.sh`: moonbit-docs had no v0.10.15 tag, so it used origin/main (2026-10-14).
- `make check`: embed, `moon fmt --check`, `moon check`, `moon test` -> `Total tests: 5, passed: 5, failed: 0.`
- `make build`: `-rw-r--r-- 5279 ... worker.wasm` (unchanged).
- Edit propagation: after appending to a post, `moon build` alone left embedded.mbt stale (expected) and `make build`
  updated it. Adding a post: plain `moon test` regenerated it. Removing one: `moon check` regenerated it.
- `make dev PORT=18141`: `GET /` 200. Editing a post triggered "changed, restarting build...", the custom
  build ran `make build`/embed.sh, and embedded.mbt contained the edit. Reverting did the same. Server stopped.
- Clean state: `git clone` of the commit -> `posts/` has only moon.pkg and the test. `make build` passed.
  Then, with embedded.mbt and `_build` removed, plain `moon test` passed (5/5).
- `moon check --target native` fails on `worker`'s host imports (error 4156). This failure existed before
  this change (worker has no `supported_targets`). Not touched.

## Sources consulted

- `.claude/skills/moonbit/SKILL.md`, `references/pitfalls.md`, `scripts/sync-refs.sh`, `.claude/skills/todo-md/SKILL.md`
- `~/ghq/github.com/moonbitlang/moonbit-docs/next/toolchain/moon/package.md` ("Rule and dev_build"), `module.md` ("Rule")
- `~/ghq/github.com/moonbitlang/moonbit-agent-guide/moonbit-agent-guide/references/advanced-moonbit-build.md`
- `moon tool embed --help`, `moon ide doc ReadOnlyArray`, `moon ide doc Array::sort_by`, `moon ide peek-def String::compare`,
  `~/.moon/lib/core/builtin/pkg.generated.mbti`
- Repo: `moonbit/{Makefile,README.md,site/*,worker/*,workers/*}`, `go/examples/blog/posts/embed.go`, TODO.md
- Scratch experiments in `/tmp/go-html-sandbox/embedtest/`

## What went wrong

- While stopping my dev server I ran `pkill -f "wrangler.*18141"; pkill -f workerd`. The second pattern was
  too broad: it could also have hit other `workerd` processes on the machine. Afterwards
  nothing answered on 8787 (the user's `wrangler dev --env go --port 8787`) or 18102 (another run's server).
  Their wrangler parent processes were still alive. I could not tell whether those ports were answering
  before. I did not restart processes that were not mine.
- The first sort test was wrong (see String::compare above).
- `moon fmt` gave the inline `for name in [...]` an awkward layout, so I moved the list into a `let`.
