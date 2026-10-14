# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

- [x] **Experiment with MoonBit's Wasm backends on Cloudflare Workers**:
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
  - [x] **Status and headers in the ABI**: let `serve` report the status
    code and the content type (e.g. through `host.status(code)` and a
    `host.header` call), so unknown paths return 404. Done when
    `curl -i` against `wrangler dev` shows 200 / 404 with the right
    `Content-Type`, and `moon test` checks the status `render` picks.
  - [x] **Makefile targets**: `moonbit/Makefile` with `build`, `test`,
    `dev`, and `deploy`, like `go/Makefile` (there is no root `Makefile`;
    each implementation is run from its own directory). Done when
    `make test dev` in `moonbit/` works from a fresh checkout.
  - [x] **Deploy**: deploy as the Worker `blog-moonbit` for now, so the Go
    `blog` stays; later whichever implementation wins is deployed as
    `blog`. Follow the steps the Go Worker uses. Done
    when the workers.dev URL serves the top page and a 404, confirming that
    Workers accepts wasm-gc uploads; record the upload size wrangler
    reports in the research notes.
  - [x] **Measure**: the Wasm size with `wasm-opt -Oz`, and the time
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
  comparison under `docs/`. Each step below ends checkable with
  `make test` and `make dev` in `moonbit/`, and deployable with
  `make deploy`. Only what the Worker serves is in scope: no `-debug` or
  `-watch`. Builds on
  [the experiment](docs/sketch/ja/moonbit-workers-wasm.md).
  - [ ] **Compare against the Go blog**: a script in `moonbit/` that
    fetches the same paths from the Go blog (`go run ./examples/blog`)
    and the MoonBit Worker (`make dev`) and diffs each response's status,
    `Content-Type`, and body. Done when it runs over `/`, a post, a
    document, `/docs/`, `/favicon.svg`, and a missing path, and reports
    which differ (all of them, at first).
  - [ ] **Embed the posts and documents**: MoonBit has no `go:embed`;
    check whether moon's pre-build step (e.g. its `:embed` command) can
    turn files into MoonBit sources, or else generate them with a script
    run by `make` and the wrangler build. Use the Go blog's posts
    (`go/examples/blog/posts/*.md`), `TODO.md`, and `docs/**/*.md`, as
    file path and content pairs, without committing the generated
    sources. Done when `moon test` checks that every one of them is
    there, and a fresh checkout builds with `make build`.
  - [ ] **HTML builder**: port `pkg/el` (nodes, escaping, rendering) and
    the part of `pkg/picoel` the pages use. Done when `moon test` covers
    the cases of their Go tests that apply, with the same output.
  - [ ] **Front matter and Markdown**: port `pkg/tinyfrontmatter` and
    `pkg/tinymarkdown` (sections up to `#####`, lists, paragraphs,
    quotes, fenced code, tables; inline code and links). Done when
    `moon test` covers the cases of their Go tests, with the same trees.
  - [ ] **Posts**: load the embedded posts (`YYYY-MM-DD-slug.md`, title
    and description from front matter or the first heading and
    paragraph) and serve `/` and `/posts/{slug}` in the Go blog's layout
    (pico.css, OGP tags from `BASE_URL`, passed in from `wrangler.jsonc`).
    Done when the comparison script shows `/` and every post the same as
    the Go blog.
  - [ ] **Documents and links**: serve `/docs/` and `/docs/{path}`, and
    resolve relative Markdown links as the Go blog does (to `/docs/` and
    `/posts/` pages, to GitHub, or not linked). Done when the comparison
    shows every document the same.
  - [ ] **The rest of the routes**: `/favicon.svg`, `/site.css?v=<hash>`,
    the `.md` sources of posts and documents, the redirects (unclean
    paths, `/docs` to `/docs/`), and the 404 page. Done when the
    comparison shows no differences over every path of the Go blog.
  - [ ] **Compare and record**: deploy, then record in the research notes
    the upload size and startup time wrangler reports, next to the TinyGo
    and standard Go builds, and the time `serve` takes for the largest
    page. Decide which implementation deploys as `blog`.

### Future work

