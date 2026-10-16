# html-sandbox/moonbit

The blog reimplemented in [MoonBit](https://www.moonbitlang.com/), to run
on Cloudflare Workers as Wasm and compare its size with the Go builds.
It is an experiment in progress; see
[the research notes](../docs/sketch/ja/moonbit-workers-wasm.md) and
`TODO.md` for what is next.

- `el` — the HTML builder ported from `go/pkg/el`: nodes as plain data,
  `render_html` (escaping like Go's `html.EscapeString`) and
  `render_plain`
- `picoel` — the part of `go/pkg/picoel` the blog's pages use: pages
  styled by pico.css v2 (`document`, `header`, `main_`, `nav`, `article`,
  `table`, ...) as `el` nodes; `date` takes a `YYYY-MM-DD` string
- `site` — the blog, ported from the Go blog's `internal/site`:
  `load_posts` and `load_docs` read the embedded files, and
  `Site::handle(req)` answers an `@http.Request` (methods other than GET
  and HEAD get the 404 page) for every route of the Go blog: `/`,
  `/posts/{slug}` and `/docs/{path}` with their `.md` sources, `/docs/`,
  `/favicon.svg`, `/site.css`, the redirects to cleaned paths, and the
  404 pages, routing with an `@http.Router`
- `assets` — the Go blog's `site.css` and `favicon.svg`, and the hash of
  `site.css` that pages put in its URL, generated into
  `assets/embedded.mbt` by `scripts/embed-assets.sh`
- `posts` — `files`, the blog's posts (`posts/*.md` in the repository root)
  as pairs of file name and content, generated into `posts/embedded.mbt`
  (ignored by git) by `scripts/embed.sh`
- `repodocs` — `files`, the repository's own `TODO.md` and
  `docs/**/*.md` as pairs of path (from the repository root) and content,
  generated into `repodocs/embedded.mbt` the same way, as the Go blog's
  `repodocs` embeds them
- `tinymarkdown` — a port of `go/pkg/tinymarkdown`: `parse(src)` into a
  tree of sections, paragraphs, lists, quotes, tables, and code blocks, and
  `inlines(text)` into text, code spans, and links; its tests are the Go
  test cases
- `tinyfrontmatter` — a port of `go/pkg/tinyfrontmatter`: `split(src)`
  into the `key: value` pairs of a leading `---` block (`None` without
  one) and the rest, raising `SplitError` on a malformed block; its tests
  are the Go test cases
- `http` — a small HTTP library, independent of the host: `Request`
  (method, URL, headers, body, and the host's variables, with the query,
  text, JSON, and urlencoded or multipart forms parsed on demand),
  `Response` with a text or binary body, and `Router`, which routes by
  patterns like Go 1.22's ServeMux (`GET /posts/{slug}`,
  `/files/{path...}`, `/{$}`), answering 405 with `Allow` and 404
- `http/wasm` — runs an `http` handler as a Wasm export:
  `handle(n, handler)` reads the request the host wrote into the linear
  memory as UTF-8 (the method, the URL, the headers, the variables, and
  the body as bytes) and writes the response over it; `adapter.mjs` is
  the host side, `wasmApp(module)`, which gives a `fetch` handler
- `worker` — the blog's Wasm entry point, a MoonBit package: `serve` and
  the linear memory exported, nothing imported; `serve` hands the request
  to `Site::handle` through `http/wasm`
- `cloudflare` — the Cloudflare Worker that runs it, in JS: `worker.mjs` runs the Wasm with
  `http/wasm/adapter.mjs`, keeping each 200 response to GET and HEAD by
  path for the rest of the isolate's life, and `wrangler.jsonc` builds it
- `experiments` — spikes kept to reproduce the numbers in the notes,
  each a module of its own outside the blog's (see its README)
- `examples/echo` — an example of `http` outside the blog (methods,
  wildcards, the query, text, JSON and form bodies, binary responses,
  cookies, and variables), run on Node by `make test-echo` and with
  wrangler by `make dev-echo`
- `compare` — compares the Go blog with the Worker path by path (status,
  `Content-Type`, and a diff of the body); `compare/cmd` is its native
  CLI, built on `moonbitlang/async`, and the only package that uses it

Strings cross between JS and Wasm as UTF-8 in the Wasm's memory because
Workers compiles imported Wasm modules without the JS string builtins,
which `use-js-builtin-string` relies on. moon emits one page of linear
memory even for wasm-gc and leaves it unused; `http/wasm` reads and
writes it with inline Wasm. See
[the notes on the http library](../docs/sketch/ja/moonbit-workers-http.md).

## Development

From `moonbit/` (`make help` lists the targets):

```sh
make test     # moon test
make build    # the Wasm, into _build/wasm-gc/release/build/worker/worker.wasm, and after wasm-opt -Oz, cloudflare/build/app.wasm
make check    # before every commit: moon fmt --check, moon check (wasm-gc and native), moon test, moon info
make test-echo  # the echo example on Node through http/wasm/adapter.mjs
```

`worker`, `http/wasm`, and `examples/echo` are built for wasm-gc only
(their inline Wasm does not compile on native) and `compare/cmd` for
native only (async's I/O is native only), so the CLI and its dependency
stay out of the Wasm.

MoonBit has no `go:embed`, so `scripts/embed.sh` writes the posts into
`posts/embedded.mbt`, and `TODO.md` and `docs/**/*.md` into
`repodocs/embedded.mbt`, as MoonBit source. `posts/moon.pkg` and
`repodocs/moon.pkg` run it before every `moon check`, `moon build`, and
`moon test`, but moon looks only at the mtime of its inputs: it reruns
the script when a post or a file directly in `docs/` is added or removed,
or `TODO.md` is edited, not when a post or document is edited or a file
in a subdirectory of `docs/` changes. `make build`, `make test`, and
`make check` run it every time (`make embed` alone), so use them after
editing a post or a document.

Needs `moon` and `moon-wasm-opt` (binaryen's `wasm-opt`, installed with
moon) on `PATH`, and Node.js for wrangler.

## Running on Workers locally

```sh
make dev            # or: make dev PORT=8798, if the Go Worker uses 8787
```

Then open <http://localhost:8787>. wrangler's build command runs
`make build`, which writes the Wasm, shrunk by `wasm-opt -Oz`, to
`cloudflare/build/app.wasm`, ignored by git, and `wrangler dev` rebuilds when `site/`, `worker/`, the posts in
`posts/`, or the documents in `docs/` change.

## Comparing with the Go blog

With the Go blog and the Worker both running:

```sh
(cd ../go && go generate ./... && go run ./examples/blog -base-url https://blog.podhmo.workers.dev)   # http://localhost:8080
make dev PORT=8798                                           # the Worker
make compare PORT=8798                                       # or GO_URL=... MOONBIT_URL=...
make compare PORT=8798 PATHS="/posts/hello /docs/"           # only these paths
```

`go generate` copies `TODO.md` and `docs/` into the Go blog; without it
the Go side serves no documents. `-base-url` gives the Go blog the
Worker's `BASE_URL` (from `cloudflare/wrangler.jsonc`), so that the OGP tags
match. For each path `compare` prints `same`, or
which of status, `Content-Type`, and body differ with a unified diff of
the body (split after each `>` and newline, since the pages are mostly on
one line; `--lines N` caps it, 40 by default). It exits non-zero when any
path differs. Redirects are not followed, so they are compared as they are.

## Deploying

```sh
make deploy
```

It deploys as the Worker `blog`, in place of the Go blog, at
<https://blog.podhmo.workers.dev>. Deploying the Go blog again puts it
back.
