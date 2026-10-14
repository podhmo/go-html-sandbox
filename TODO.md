# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [ ] **blog: rewrite the stale sample post `2026-10-16-mobile-first.md`**:
  it still describes the old inline stylesheet (custom properties, clamp(),
  prefers-color-scheme, ...), but pages now use pico.css v2 in its dark
  theme, plus a small `site.css` for what pico cannot express.

- [x] **tinymarkdown: links**: parse `[text](url)` into a link inline
  (alongside `` `code` `` spans) and render it as `<a>` in the blog; today
  it shows as raw text, e.g. the note at the top of `TODO.md`. Decide how
  relative links between repository files (`docs/...md`, `.claude/...`)
  map to `/docs/` URLs or elsewhere.

### Future work

- [ ] **Run `examples/blog` on Cloudflare Workers with TinyGo**: split the entry
  point by build tag so the default build stays standard-library only,
  and serve the same `http.Handler` via
  [syumai/workers-go](https://github.com/syumai/workers-go) under TinyGo.
  Far off; check that `pkg/*` and `go:embed` work under TinyGo first.
  Spike: [report](docs/sketch/ja/blog-tinygo-workers.md), branches
  `spike/tinygo-workers` (build tags) and `spike/tinygo-workers-module`
  (separate module).
