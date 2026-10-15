# Port of pkg/el to moonbit/el (without the moonbit skill)

## What was done

Commit `e3c0f84` on top of `4bed4b9` in the clone (not pushed).

- `moonbit/el/node.mbt`: `Tag` and `AttrName` newtypes (`struct Tag(String)`),
  and `Node` as a closed enum (`Text`, `Raw`, `Element(Tag, Array[Node])`,
  `Attr(AttrName, String)`, `BoolAttr(AttrName)`) deriving `Eq, Debug`, plus
  the helpers `el`, `attr`, `bool_attr`, `text`, `raw`. Go's variadic
  `El(name, children...)` becomes `el(name, [children])`.
- `moonbit/el/const.mbt`: the element and attribute names from `const.go`
  as `pub let` values. Keyword clashes renamed to `type_` and `defer_`;
  `TitleAttr` became `title_attr`.
- `moonbit/el/render.mbt`: a `Renderer` trait (`text`, `raw`, `element`,
  `attr`, `bool_attr`, writing to `&Logger`), `render` as the single dispatch,
  `escape` (same as Go's `html.EscapeString`: `&lt; &gt; &amp; &#39; &#34;`),
  `HtmlRenderer` (void elements drop their content), `PlainRenderer` (block
  elements on their own lines; it tracks the last char written instead of
  using Go's `lineWriter`, so use a new one for each output), and
  `to_html` / `to_plain`.
- `moonbit/el/moon.pkg`: `warnings = "-implicit_impl_as_method"` to turn off
  the deprecation warning about derived `Eq`/`Debug` methods being promoted
  to regular methods.
- Tests: `node_test.mbt` (constructors, leaf nodes comparable) and
  `render_test.mbt` (every applicable HTML renderer and plain renderer case,
  with the same expected strings as Go, plus an extra escape test).
  Not ported because they do not apply: "nil child is skipped" and
  `TestRenderUnknownNode` (`Node` is a closed enum with no nil), and
  `TestRenderPropagatesWriteError` (writing to a `&Logger` cannot fail).
- `moonbit/README.md`: listed the `el` package.
- `TODO.md`: "HTML ビルダー" is now `[-]`, with children `pkg/el` `[x]` and
  `pkg/picoel` `[ ]`. Its parent, "ブログを MoonBit で作り直す", is set to `[-]`.
- `site` was not changed to use `el`. It still has its own `write_escaped`,
  which uses `&quot;`. This was not requested.

## Commands and results

- `moon version` -> `moon 0.1.20261012`
- `moon check` iterations, each fixed: `derive(Show)` is deprecated, so it
  became `Debug`; `"warn-list"` is deprecated, so it became a top-level
  `warnings = ...`; the unit struct value needed `HtmlRenderer::{}`.
- `moon fmt`, `moon test` -> `Total tests: 7, passed: 7, failed: 0.`
- Mutation check: changing the `"` escape to `&quot;` made 2 tests fail.
  Reverted.
- `make build` -> worker.wasm 5279 bytes (the worker does not link `el` yet)
- `make check`:
  ```
  moon fmt --check
  Finished. moon: no work to do
  moon check
  Finished. moon: no work to do
  moon test
  Total tests: 7, passed: 7, failed: 0.
  ```
- No server was started.

## Sources consulted

- `go/pkg/el/{node,const,render}.go` and their tests
- the existing `moonbit/` code (`site`, `worker`, `Makefile`, the `moon.pkg` files)
- the MoonBit core under `~/.moon/lib/core`, for the trait and tuple-struct
  syntax and the `assert_eq` signature (`pkg.generated.mbti`)
- `.claude/skills/todo-md/SKILL.md`, for the TODO.md update. No MoonBit skill
  was used.

## What went wrong

Only the compiler-guided fixes listed above. Nothing is left open.
