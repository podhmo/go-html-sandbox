# Port pkg/tinymarkdown to moonbit/ (without the moonbit skill)

## What was done

- New package `moonbit/tinymarkdown` (the Go code lives in `go/pkg/tinymarkdown`):
  - `tinymarkdown.mbt`: `Document { children }`, `enum Block` (`Section(level~, title~, children~)`,
    `Paragraph`, `List`, `Quote`, `Table(header~, rows~)`, `CodeBlock`), `parse(src)`.
    This is a line-by-line port of `scan`, `parse_table`, `cells`, `is_delimiter`, `is_heading`,
    `parse_heading`, and `nest`. Headings stay as a private `Flat::Heading` marker until `nest` runs.
  - `inline.mbt`: `enum Inline` (`Text`, `Code`, `Link(children~, url~)`), `inlines(s)`.
  - `extends.mbt`: `pub extend ... with Eq::{...}` / `Debug::{to_repr}`. This silences the
    `implicit_impl_as_method` deprecation warnings that `derive(Eq, Debug)` produces.
  - `moon.pkg`: imports `moonbitlang/core/debug`, which `extends.mbt` needs (warning 0071 otherwise).
  - `trim` uses the same character set as Go's `unicode.IsSpace`. MoonBit's default `trim` only
    removes `\t\n\r `, but `strings.TrimSpace` also removes characters such as U+3000 and U+00A0.
- Tests:
  - `tinymarkdown_test.mbt` has all 57 cases of `tinymarkdown_test.go`.
  - `inline_test.mbt` has all 31 cases of `inline_test.go`.
  - Each case is its own `test "group/name"` block with the Go case name. Each one checks the
    whole tree with `assert_eq`.
  - Two extra non-ASCII cases (Japanese text, U+3000, an emoji in a table cell and in a code span).
    I took their expected trees from the Go version: I ran a throwaway Go test and deleted it.
- `moonbit/README.md`: added `tinymarkdown` to the package list.
- `TODO.md`: the "front matter と Markdown" item is now `[-]` with two children: Markdown `[x]`,
  front matter `[ ]`. The user said tinyfrontmatter can wait. `TODO-archive.md` is untouched.
- One commit on main in the clone (3b93904). Nothing was pushed.

## Commands and results

- `moon test` (in moonbit/): `Total tests: 92, passed: 92, failed: 0.` That is 2 existing site
  tests, 57 + 31 ported cases, and 2 extra cases.
- `make check`:
  ```
  moon fmt --check
  Finished. moon: ran 12 tasks, now up to date
  moon check
  Finished. moon: ran 2 tasks, now up to date
  moon test
  Total tests: 92, passed: 92, failed: 0.
  ```
  No warnings.
- `make build`: worker.wasm is 5279 bytes. The worker does not import tinymarkdown yet.
- Mutation check: I changed one expected value and the test failed with a readable diff. Then I
  reverted the change.
- `go test ./pkg/tinymarkdown -run TestZZ -v` with a temporary test, to get the Go trees for the
  non-ASCII inputs.
- No servers were started.

## Sources consulted

- `go/pkg/tinymarkdown/*.go` (implementation and tests), `TODO.md`, `moonbit/` (existing
  package layout, Makefile, README), `.claude/skills/todo-md/SKILL.md`.
- The MoonBit core library in `~/.moon/lib/core`:
  - `builtin/pkg.generated.mbti` and `builtin/stringview.mbt`: `s[a:b]` is `clamped_view` (it
    never raises, and it snaps cuts that would split a surrogate pair), and `String::trim`'s
    default chars.
  - `prelude` / `debug` `.mbti`: `assert_eq` needs `Eq + Debug`.
  - `json/extends.mbt`: the `pub extend ... with` pattern.
- A scratch `moon new` project in `run-1/scratch`, to check that char literals compare against the
  `UInt16` that `s[i]` returns.
- I did not use or read the moonbit skill.

## What went wrong / notes

- The first version of `cells` copied one code unit at a time with `b.write_view(line[i:i+1])`.
  Because `[i:i+1]` is a clamped view, it dropped both halves of a surrogate pair, so a table cell
  holding an emoji came out empty. The non-ASCII test caught it. `cells` now copies text in runs
  between the `|` / `\|` delimiters.
- `.to_string()` on a `StringView` is deprecated in this moon version (0.1.20261012). The code uses
  `.to_owned()`.
- Go tells a nil slice from an empty one; MoonBit arrays do not. This makes no difference to the
  comparisons: the Go tests never expect an empty non-nil slice.
