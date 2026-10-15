# Summary: port pkg/tinymarkdown to moonbit/

## What was done

- New package `moonbit/tinymarkdown` (`podhmo/blog/tinymarkdown`), a port of `go/pkg/tinymarkdown`:
  - `tinymarkdown.mbt`: `pub(all) struct Document { children }`, `pub(all) enum Block` (`Section(level~, title~, children~)`, `Paragraph`, `List`, `Quote`, `Table(header~, rows~)`, `CodeBlock`), `pub fn parse(src) -> Document`. scan / parse_table / cells / is_delimiter / is_heading / nest follow the Go code one to one; the Go-private `heading` marker became a private enum `Flat`.
  - `inline.mbt`: `pub(all) enum Inline` (`Text`, `Code`, `Link(children~, url~)`), `pub fn inlines(s)`.
  - Go's `strings.TrimSpace` is reproduced with a constant holding the `unicode.IsSpace` set, because core's `trim()` default is only `"\t\n\r "`.
  - Byte indexes (Go) vs UTF-16 code-unit indexes (MoonBit) agree since every syntax character is ASCII.
- Tests: `tinymarkdown_test.mbt` (TestSectionsAndParagraphs/Lists/CodeBlocks/Quotes/Tables: 57 cases) and `inline_test.mbt` (TestInlines: 31 cases), comparing whole trees with `==`. The case tables were generated from the Go literals by a throwaway converter in /tmp/go-html-sandbox/mbscratch/conv (not in the repo), and the counts were checked against Go. A failing case is reported by name with got/want, like Go's t.Errorf. `moon.pkg` imports `moonbitlang/core/debug` for "test".
- Verified the tests bite: temporarily setting max_level = 6 failed "###### is not a heading" with a readable got/want; reverted.
- `pkg/tinyfrontmatter` was NOT ported (as requested).
- Docs: `moonbit/README.md` package list; `docs/sketch/ja/moonbit-workers-wasm.md` new section 「Markdown の移植」 (findings, Japanese); `TODO.md` entry 「front matter と Markdown」 changed to `[-]` with only tinyfrontmatter remaining (per todo-md skill).
- Commit: `bc4caeb moonbit: port pkg/tinymarkdown, checked against the Go test cases` (no push).

## Commands and results

- `moon version` -> 0.1.20261012; latest from cli.moonbitlang.com/version.json is the same, so no upgrade needed.
- `.claude/skills/moonbit/scripts/sync-refs.sh` -> core 0.10.15+943464bfa; moonbit-docs at origin/main (no v0.10.15 tag yet). No x/async deps in moon.mod.
- Scratch module in /tmp/go-html-sandbox/mbscratch/s to confirm `s[i] == '`'`, `s[a:b]` slicing, `to_owned()` (StringView::to_string is deprecated), `trim(chars=...)`.
- `make check` (in moonbit/):
  ```
  moon fmt --check
  Finished. moon: ran 11 tasks, now up to date
  moon check
  Finished. moon: ran 2 tasks, now up to date
  moon test
  Total tests: 8, passed: 8, failed: 0.
  ```
- `make build`: worker.wasm 5279 B, unchanged (worker does not import tinymarkdown yet). No watch_dir change needed for the same reason.
- `go test ./pkg/tinymarkdown/` -> ok (reference).
- No server was started.

## Sources consulted

- go/pkg/tinymarkdown/{tinymarkdown.go,inline.go,tinymarkdown_test.go,inline_test.go}
- .claude/skills/moonbit/SKILL.md, references/pitfalls.md; .claude/skills/todo-md/SKILL.md
- moonbit-docs next/language/derive.md, methods.md (extend), sources/language/src/derive/*.mbt; next/toolchain/moon/package.md (test import `for "test"`)
- ~/.moon/lib/core builtin/pkg.generated.mbti, string_methods.mbt (trim default chars), debug/debug.mbt (assert_eq: `msg` replaces the diff, hence the custom reporting); `moon ide doc`

## What went wrong / notes

- `derive(Eq, Debug)` on pub types warns `implicit_impl_as_method` (0079). A private `extend` trades it for unused-function warnings, so `pub extend T with Eq::{not_equal, equal}` / `Debug::{to_repr}` was used, as the official derive examples do.
- `moon fmt` spells types as written (`Int`); the earlier repo commit mentioning Int32 did not affect fmt --check.
