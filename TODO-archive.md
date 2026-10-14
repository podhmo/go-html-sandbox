# TODO archive

> **What this file is:** append-only history of completed work moved out of
> `TODO.md` by a periodic GC sweep (see `.claude/skills/todo-md/SKILL.md` —
> feature PRs never write here, so this file never conflicts). Entries land
> **verbatim** at the end of the file as `- [x]` lines; nested items get a
> `> parent: <title>` context line first. Entries are never rewritten;
> links into docs, issues, and PRs are preserved.
>
> **Reading this file:** do not read it whole — `grep` for a symbol or
> feature name, then read only the surrounding lines (`rg -C` / read with
> an offset).

- [x] **Core `pkg/el`** ([design](docs/ja/design.md)): the scope the blog
  needs first; more elements/attributes are added as const lines later.
> parent: Core `pkg/el`
- [x] **Node types and constructors**: `Node`, `Tag` / `AttrName` consts,
  `El`, `Attr`, `Text`, `Raw`. Tests compare trees with
  `reflect.DeepEqual`.
> parent: Core `pkg/el`
- [x] **`HTMLRenderer`**: escaping in `Text`, void elements, attributes
  vs. children. Table tests on rendered strings, including an XSS case.
> parent: Core `pkg/el`
- [x] **`PlainRenderer`**: text-only output. Tests for nested elements
  and dropped attributes.
- [x] **`Parse(src) Document`** ([sketch](docs/sketch/ja/blog.md)): pure-data
  AST with no dependency on `pkg/el`. Table tests compare ASTs with
  `reflect.DeepEqual`.
> parent: `Parse(src) Document`
- [x] **Sections**: `#`–`###` nest into `Section`; content before the
  first heading goes to `Document.Children`. Tests for nesting and
  level jumps.
> parent: `Parse(src) Document`
- [x] **Lists and paragraphs**: consecutive `- ` lines form one `List`;
  other non-empty lines join into a `Paragraph`; blank lines separate.
> parent: `Parse(src) Document`
- [x] **Code blocks**: ```` ``` ```` fences only; the info string is
  ignored and contents are kept verbatim (including `#`, `- `, blank
  lines). Tests for an unclosed fence running to EOF.
- [x] **Mobile-first blog** ([sketch](docs/sketch/ja/blog.md)): handlers
  tested with `httptest` over a `fstest.MapFS`, body checks via
  `PlainRenderer`.
> parent: Mobile-first blog
- [x] **Post loading**: `loadPosts(fs.FS)` over `//go:embed posts/*.md`;
  date and slug from `YYYY-MM-DD-slug.md`, title from the first `#`.
  Tests for bad file names and duplicate slugs (startup error).
> parent: Mobile-first blog
- [x] **Post list and post page**: `GET /{$}` (newest first) and
  `GET /posts/{slug}`, built by `layout` / `postList` / `postPage` and
  `renderBlocks` (AST → `el.Node`, code blocks as `<pre>`).
> parent: Mobile-first blog
- [x] **Error pages**: 404 for unknown slugs and unmatched URLs, 500 via
  a `recover` middleware; render into `bytes.Buffer` first. Tests that
  the 500 page leaks no internal details.
> parent: Mobile-first blog
- [x] **Favicon**: embedded `favicon.svg` at `GET /favicon.svg` with
  `Content-Type` and `Cache-Control`. Test the headers.
> parent: Mobile-first blog
- [x] **Mobile-first CSS**: inline `<style>` via `Raw`, no build step,
  under ~100 lines (dark mode, 44px tap targets, scrollable `<pre>`).
> parent: Mobile-first blog
- [x] **Sample posts**: a few posts in `cmd/blog/posts/` that exercise
  every supported Markdown construct.
- [x] **Readable `PlainRenderer` output**: text of adjacent elements is
  glued together (`blog2026-10-14Hello`). Separate block-level elements
  (e.g. with newlines) and update tests in `pkg/el` and `cmd/blog`.
- [x] **Tiny front matter**: split a leading `---` block of `key: value`
  lines from the Markdown body, as a separate package next to
  `pkg/tinymarkdown`. Errors for an unclosed block, a line without `:`,
  and duplicate keys.
- [x] **Front matter in posts**: `title` and `description` from
  `pkg/tinyfrontmatter`, falling back to the first `#` heading and the
  first paragraph; `description` also feeds `<meta name="description">`
  and OGP.
- [x] **OGP support**: `og:title`, `og:type` (`website` / `article`),
  `og:url`, `og:description` (the post's description), `og:site_name`.
  Needs a base URL flag for absolute URLs and a `property` attribute
  const in `pkg/el`; `og:image` is out of scope for now.
