# Port pkg/el to moonbit/el

## What was done

Ported `go/pkg/el` (nodes, escaping, rendering) to a new MoonBit package `moonbit/el`. `picoel` was left out, as requested. Committed as `81de235 moonbit: port pkg/el to moonbit/el` (not pushed).

New files in `moonbit/el/`:
- `moon.pkg` is empty, with no imports.
- `node.mbt` has `Tag(String)` and `AttrName(String)`, which are distinct `pub(all)` tuple structs. It also has `pub(all) enum Node { Text, Raw, Element(Tag, Array[Node]), Attr(AttrName, String), BoolAttr(AttrName) } derive(Eq, Debug)`, and `el(name, children)`.
- `const.mbt` has every element and attribute constant from `const.go`, as `pub let div : Tag = Tag("div")`.
  - `const` cannot be used: error E4143 says only primitive types are allowed. I verified this in a scratch module.
  - Attribute names that are MoonBit keywords get an `_attr` suffix, following Go's `TitleAttr` convention: `defer_attr` and `type_attr`.
- `render.mbt` has `render_html(Node) -> String` and `render_plain(Node) -> String`.
  - Go's `Renderer` interface and type switch became a `match` on the closed enum.
  - Escaping matches Go's `html.EscapeString`: `&#34;` and `&#39;`.
  - The void-element and block-element sets are string `match`es.
  - Go's `lineWriter` became a private `LineWriter` that tracks whether the output is at the start of a line.
- `extends.mbt` silences warning [0079] `implicit_impl_as_method`.
  - With moonc v0.10.15, `derive(Eq, Debug)` on a pub type warns on its own; I reproduced this in a scratch module.
  - The fix is `#deprecated pub extend X with Eq::{equal, not_equal}` / `Debug::{to_repr}`. This follows the diagnostic's suggestion and core's `cmp/extends.mbt`.
- `el_test.mbt` is a blackbox test that ports the Go cases.
  - From `TestConstructors` and `TestLeafNodesAreComparable`: all cases.
  - From `TestHTMLRenderer`: 10 of 11 cases.
  - From `TestPlainRenderer`: all 9 cases.
  - Expected strings are identical to Go's.
  - It also adds one test pinning the escape set and non-ASCII passthrough.
  - Not ported, because they cannot be represented: "nil child is skipped" (MoonBit has no nil), `TestRenderUnknownNode` (the enum is closed), and `TestRenderPropagatesWriteError` (a StringBuilder cannot fail).

Other edits:
- `TODO.md`: following the todo-md skill, "HTML ビルダー" became `[-]` with two children: `[x] el` and `[ ] picoel`.
- `moonbit/README.md`: added `el` to the package list.
- `docs/sketch/ja/moonbit-workers-wasm.md`: new section "HTML ビルダー（`el`）" covering the design, the skipped tests, the escaping difference from `site` (`&quot;` vs `&#34;`), and the 0079 warning.

## Commands and results

- `moon version --all`: moon 0.1.20261012, moonc v0.10.15. This equals `https://cli.moonbitlang.com/version.json`, so no upgrade was needed.
- `.claude/skills/moonbit/scripts/sync-refs.sh` used core from `~/.moon/lib/core`. moonbit-docs has no v0.10.15 tag yet, so it uses origin/main (2026-10-14).
- Baseline `make check`: passed, 2 tests.
- `make build`: `worker.wasm` is 5279 B both before and after, because `worker` does not import `el` yet.
- Final `make check`:
  ```
  moon fmt --check
  Finished. moon: ran 6 tasks, now up to date
  moon check
  Finished. moon: ran 2 tasks, now up to date
  moon test
  Total tests: 7, passed: 7, failed: 0.
  ```
  That is 2 site tests plus 5 el tests. There are no warnings.

No server was started.

## Sources consulted

- `.claude/skills/moonbit/SKILL.md`, `references/pitfalls.md`, `.claude/skills/todo-md/SKILL.md`
- `go/pkg/el/{node,const,render}.go` and `*_test.go`
- `moonbit/site/site.mbt` and its test, which I used as the style model
- `moonbit-docs/next/language/{introduction,fundamentals,derive}.md`: keywords, tuple structs, const, derive
- `moon ide doc assert_eq` and `moon ide doc StringBuilder`
- `moon explain --diagnostic 0079` and `4143`
- `~/.moon/lib/core/cmp/extends.mbt` for the extend pattern

## What went wrong / notes

- The first `moon check` gave 6 warnings [0079] from the derives. They are fixed in `extends.mbt`.
  - My first version used `@debug.Debug`, which raised [0071] `core_package_not_imported`. Plain `Debug` from the prelude fixed it.
- `moon fmt` changed the layout of a struct literal and of the test arrays; the reformatted result is what was committed.
- `site` still has its own escaper using `&quot;`. Switching `site` to `el` is left for the page-rendering steps.
