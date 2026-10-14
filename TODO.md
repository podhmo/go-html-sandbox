# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [ ] **Experiment with MoonBit's Wasm backends on Cloudflare Workers**:
  before porting the blog, put a spike under `moonbit/` that serves pages
  from `wasm-gc` (without `use-js-builtin-string`, which Workers cannot
  compile for) through the code-unit ABI, extend the ABI with status and
  headers, deploy it to check that Workers accepts wasm-gc, and measure
  `wasm-opt` and the cost of the per-code-unit calls. See
  [the research notes](docs/sketch/ja/moonbit-workers-wasm.md).

- [ ] **Reimplement the blog in MoonBit**: build the same site under a
  top-level `moonbit/` directory, run it on Cloudflare Workers as Wasm, and
  compare the Wasm size with the Go builds (TinyGo about 2 MiB / 760 KiB
  gzipped, standard Go about 8 MiB; see
  [the report](docs/sketch/ja/blog-tinygo-workers.md)). Decide how much of
  `pkg/*` (HTML builder, Markdown parser) to port, and record the
  comparison under `docs/`.

### Future work

