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

### Future work

- [ ] **Run `examples/blog` on Cloudflare Workers with TinyGo**: split the entry
  point by build tag so the default build stays standard-library only,
  and serve the same `http.Handler` via
  [syumai/workers-go](https://github.com/syumai/workers-go) under TinyGo.
  Far off; check that `pkg/*` and `go:embed` work under TinyGo first.
