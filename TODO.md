# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [ ] **Reimplement the blog in MoonBit**: build the same site under a
  top-level `moonbit/` directory, run it on Cloudflare Workers as Wasm, and
  compare the Wasm size with the Go builds (TinyGo about 2 MiB / 760 KiB
  gzipped, standard Go about 8 MiB; see
  [the report](docs/sketch/ja/blog-tinygo-workers.md)). Decide how much of
  `pkg/*` (HTML builder, Markdown parser) to port, and record the
  comparison under `docs/`.

### Future work

