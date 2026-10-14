# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

### pkg/el (HTML library)

- [x] **Core `pkg/el`** ([design](docs/ja/design.md)): the scope the blog
  needs first; more elements/attributes are added as const lines later.
  - [x] **Node types and constructors**: `Node`, `Tag` / `AttrName` consts,
    `El`, `Attr`, `Text`, `Raw`. Tests compare trees with
    `reflect.DeepEqual`.
  - [x] **`HTMLRenderer`**: escaping in `Text`, void elements, attributes
    vs. children. Table tests on rendered strings, including an XSS case.
  - [x] **`PlainRenderer`**: text-only output. Tests for nested elements
    and dropped attributes.

### pkg/tinymarkdown (tiny Markdown parser)

- [x] **`Parse(src) Document`** ([sketch](docs/sketch/ja/blog.md)): pure-data
  AST with no dependency on `pkg/el`. Table tests compare ASTs with
  `reflect.DeepEqual`.
  - [x] **Sections**: `#`–`###` nest into `Section`; content before the
    first heading goes to `Document.Children`. Tests for nesting and
    level jumps.
  - [x] **Lists and paragraphs**: consecutive `- ` lines form one `List`;
    other non-empty lines join into a `Paragraph`; blank lines separate.
  - [x] **Code blocks**: ```` ``` ```` fences only; the info string is
    ignored and contents are kept verbatim (including `#`, `- `, blank
    lines). Tests for an unclosed fence running to EOF.

### cmd/blog (application)

- [x] **Mobile-first blog** ([sketch](docs/sketch/ja/blog.md)): handlers
  tested with `httptest` over a `fstest.MapFS`, body checks via
  `PlainRenderer`.
  - [x] **Post loading**: `loadPosts(fs.FS)` over `//go:embed posts/*.md`;
    date and slug from `YYYY-MM-DD-slug.md`, title from the first `#`.
    Tests for bad file names and duplicate slugs (startup error).
  - [x] **Post list and post page**: `GET /{$}` (newest first) and
    `GET /posts/{slug}`, built by `layout` / `postList` / `postPage` and
    `renderBlocks` (AST → `el.Node`, code blocks as `<pre>`).
  - [x] **Error pages**: 404 for unknown slugs and unmatched URLs, 500 via
    a `recover` middleware; render into `bytes.Buffer` first. Tests that
    the 500 page leaks no internal details.
  - [x] **Favicon**: embedded `favicon.svg` at `GET /favicon.svg` with
    `Content-Type` and `Cache-Control`. Test the headers.
  - [x] **Mobile-first CSS**: inline `<style>` via `Raw`, no build step,
    under ~100 lines (dark mode, 44px tap targets, scrollable `<pre>`).
  - [x] **Sample posts**: a few posts in `cmd/blog/posts/` that exercise
    every supported Markdown construct.
