# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [x] **blog: rewrite the stale sample post `2026-10-16-mobile-first.md`**:
  it still describes the old inline stylesheet (custom properties, clamp(),
  prefers-color-scheme, ...), but pages now use pico.css v2 in its dark
  theme, plus a small `site.css` for what pico cannot express.

- [x] **blog: update the stale sample post `2026-10-15-tinymarkdown.md`**:
  it says headings stop at `###` and shows `####` as unsupported, and
  does not mention links or pipe tables, all of which tinymarkdown now
  supports.

- [x] **tinymarkdown: links**: parse `[text](url)` into a link inline
  (alongside `` `code` `` spans) and render it as `<a>` in the blog; today
  it shows as raw text, e.g. the note at the top of `TODO.md`. Decide how
  relative links between repository files (`docs/...md`, `.claude/...`)
  map to `/docs/` URLs or elsewhere.
- [x] **tinymarkdown: headings up to `#####`**: raise `maxLevel` from 3
  to 5 so `####` and `#####` open nested sections (rendered as `<h4>` and
  `<h5>` in the blog); today they are shown as paragraph text. See
  [the sketch](docs/sketch/ja/blog.md).

- [x] **tinymarkdown: tables**: parse GitHub-style pipe tables (header
  row, `| --- |` delimiter row, body rows) into a table block, with
  inline syntax in cells, and render them as `<table>` in the blog.
  `docs/sketch/ja/blog.md` and `docs/sketch/ja/blog-tinygo-workers.md`
  use tables, which are shown as raw `|` text today. Decide whether to
  honor column alignment (`:---:`).
- [x] **blog: render inline Markdown in titles of the post and doc lists**:
  `postList` and `docList` write the title with `pe.Text`, so a title such
  as ``実験レポート: `examples/blog` を …`` shows its backticks literally.
  Render it with `renderInlines` like the page heading (dropping links,
  since the title is already a link), and strip the markup from `<title>`
  and `og:title`.

### Future work

- [x] **Run `examples/blog` on Cloudflare Workers with TinyGo**: split the entry
  point by build tag so the default build stays standard-library only,
  and serve the same `http.Handler` via
  [syumai/workers-go](https://github.com/syumai/workers-go) under TinyGo.
  Far off; check that `pkg/*` and `go:embed` work under TinyGo first.
  Spike: [report](docs/sketch/ja/blog-tinygo-workers.md), branches
  `spike/tinygo-workers` (build tags) and `spike/tinygo-workers-module`
  (separate module).
