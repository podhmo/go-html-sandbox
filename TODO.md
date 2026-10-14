# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [-] **Experiment with MoonBit's Wasm backends on Cloudflare Workers**:
  before porting the blog, get a MoonBit Worker under `moonbit/` that can
  be checked locally and deployed, serving pages from `wasm-gc` (without
  `use-js-builtin-string`, which Workers cannot compile for) through the
  code-unit ABI. See
  [the research notes](docs/sketch/ja/moonbit-workers-wasm.md).
  - [x] **Scaffold `moonbit/`**: a MoonBit module (`moon.mod`, `moon.pkg`)
    whose `render` builds the top page and a 404 page, with `moon test`
    covering both. Done when `moon test` passes and
    `moon build --target wasm-gc --release` writes a Wasm exporting only
    `path_push` and `serve` and importing only `host.put`.
  - [x] **Worker shell and `wrangler dev`**: `moonbit/workers/` with the
    spike's `worker.mjs` and a `wrangler.jsonc` whose build command runs
    the MoonBit build and copies the Wasm next to `worker.mjs` (ignored by
    git). Done when `npx wrangler dev` in it serves the top page, and a
    path with `<` shows escaped.
  - [ ] **Status and headers in the ABI**: let `serve` report the status
    code and the content type (e.g. through `host.status(code)` and a
    `host.header` call), so unknown paths return 404. Done when
    `curl -i` against `wrangler dev` shows 200 / 404 with the right
    `Content-Type`, and `moon test` checks the status `render` picks.
  - [ ] **Makefile targets**: `moonbit/Makefile` with `build`, `test`,
    `dev`, and `deploy`, like `go/Makefile` (there is no root `Makefile`;
    each implementation is run from its own directory). Done when
    `make test dev` in `moonbit/` works from a fresh checkout.
  - [ ] **Deploy**: deploy as the Worker `blog-moonbit` for now, so the Go
    `blog` stays; later whichever implementation wins is deployed as
    `blog`. Follow the steps the Go Worker uses. Done
    when the workers.dev URL serves the top page and a 404, confirming that
    Workers accepts wasm-gc uploads; record the upload size wrangler
    reports in the research notes.
  - [ ] **Measure**: the Wasm size with `wasm-opt -Oz`, and the time
    `serve` spends on per-code-unit calls for a page of about 50 KB
    (locally under `wrangler dev`). Record both in the research notes, and
    if the calls are slow, sketch an ABI passing UTF-8 bytes through
    linear memory instead.

- [ ] **Reimplement the blog in MoonBit**: build the same site under a
  top-level `moonbit/` directory, run it on Cloudflare Workers as Wasm, and
  compare the Wasm size with the Go builds (TinyGo about 2 MiB / 760 KiB
  gzipped, standard Go about 8 MiB; see
  [the report](docs/sketch/ja/blog-tinygo-workers.md)). Decide how much of
  `pkg/*` (HTML builder, Markdown parser) to port, and record the
  comparison under `docs/`.

### Future work

