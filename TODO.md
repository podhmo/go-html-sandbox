# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [x] **`pkg/picoel`: pico.css v2 building blocks for the blog**: add a
  package with only the elements the blog needs, built on `pkg/el` and
  following the rules in `../podhmo.github.io/ui/pico/README.md` (no custom
  classes or CSS, semantic elements first, `.container` on
  `header`/`main`/`footer`, pico v2 from the CDN). Rewrite `examples/blog` to
  import only `picoel` (no direct `pkg/el`) and drop `style.go`.

- [x] **Dark mode for the blog**: render every page in pico's dark theme
  (`data-theme="dark"` on `<html>`) instead of following the OS setting.

- [x] **`examples/parse-markdown`: dump the tinymarkdown tree**: a small
  CLI that parses Markdown files (or stdin) with `pkg/tinymarkdown` and
  prints the resulting tree, to check how documents such as `TODO.md` and
  `docs/**/*.md` are understood before embedding them in the blog.

- [x] **tinymarkdown: list items spanning several lines**: indented lines
  after a `- ` item should continue that item instead of starting a
  paragraph. Today every multi-line entry in `TODO.md` splits into a
  one-line list plus a paragraph (check with `examples/parse-markdown`).

- [x] **Serve `TODO.md` and `docs/` in the blog**: embed them with
  `go:embed` from a package at the repository root (embed cannot reach
  `..`), parse them with tinymarkdown at startup, and serve them under
  `/docs/` with an index page and a nav link.

- [x] **tinymarkdown: blockquotes**: consecutive `>` lines become a `Quote`
  whose content is parsed as Markdown again; render it as `<blockquote>`
  in the blog (the note at the top of `TODO.md` is one).

- [ ] **tinymarkdown: inline code**: split text into plain runs and
  `` `code` `` spans (CommonMark-style backtick runs) and render the spans
  as `<code>` in headings, paragraphs, and list items.

### Future work

- [ ] **Run `examples/blog` on Cloudflare Workers with TinyGo**: split the entry
  point by build tag so the default build stays standard-library only,
  and serve the same `http.Handler` via
  [syumai/workers-go](https://github.com/syumai/workers-go) under TinyGo.
  Far off; check that `pkg/*` and `go:embed` work under TinyGo first.
