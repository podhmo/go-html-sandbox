# html-sandbox/moonbit

The blog reimplemented in [MoonBit](https://www.moonbitlang.com/), to run
on Cloudflare Workers as Wasm and compare its size with the Go builds.
It is an experiment in progress; see
[the research notes](../docs/sketch/ja/moonbit-workers-wasm.md) and
`TODO.md` for what is next.

- `el` — the HTML builder ported from `go/pkg/el`: nodes as plain data,
  `render_html` (escaping like Go's `html.EscapeString`) and
  `render_plain`
- `site` — `render(path)`, returning the response for a path: status,
  headers, and body
- `posts` — `files`, the Go blog's posts (`go/examples/blog/posts/*.md`)
  as pairs of file name and content, generated into `posts/embedded.mbt`
  (ignored by git) by `scripts/embed.sh`
- `worker` — the Wasm entry point: `path_push` and `serve` exported, the
  response sent back through the imported `host` functions (`status`,
  then `put` for text one UTF-16 code unit at a time, with `header_name`
  and `header_value` taking what was put as a header; the rest is the
  body)
- `workers` — the Cloudflare Worker: `worker.mjs` runs the Wasm for each
  request, and `wrangler.jsonc` builds it
- `compare` — compares the Go blog with the Worker path by path (status,
  `Content-Type`, and a diff of the body); `compare/cmd` is its native
  CLI, built on `moonbitlang/async`, and the only package that uses it

Strings cross between JS and Wasm one code unit at a time because Workers
compiles imported Wasm modules without the JS string builtins, which
`use-js-builtin-string` relies on.

## Development

From `moonbit/` (`make help` lists the targets):

```sh
make test     # moon test
make build    # the Wasm, into _build/wasm-gc/release/build/worker/worker.wasm
make check    # before every commit: moon fmt --check, moon check (wasm-gc and native), moon test
```

`worker` is built for wasm-gc only (its host imports do not compile on
native) and `compare/cmd` for native only (async's I/O is native only),
so the CLI and its dependency stay out of the Wasm.

MoonBit has no `go:embed`, so `scripts/embed.sh` writes the posts into
`posts/embedded.mbt` as MoonBit source. `posts/moon.pkg` runs it before
every `moon check`, `moon build`, and `moon test`, but moon reruns it only
when a post is added or removed, not when one is edited; `make build`,
`make test`, and `make check` run it every time (`make embed` alone), so
use them after editing a post.

Needs `moon` on `PATH`, and Node.js for wrangler.

## Running on Workers locally

```sh
make dev            # or: make dev PORT=8798, if the Go Worker uses 8787
```

Then open <http://localhost:8787>. wrangler's build command runs
`make build` and copies the Wasm to `workers/build/app.wasm`, ignored by
git, and `wrangler dev` rebuilds when `site/`, `worker/`, or the posts in
`go/examples/blog/posts/` change.

## Comparing with the Go blog

With the Go blog and the Worker both running:

```sh
(cd ../go && go generate ./... && go run ./examples/blog)   # http://localhost:8080
make dev PORT=8798                                           # the Worker
make compare PORT=8798                                       # or GO_URL=... MOONBIT_URL=...
make compare PORT=8798 PATHS="/posts/hello /docs/"           # only these paths
```

`go generate` copies `TODO.md` and `docs/` into the Go blog; without it
the Go side serves no documents. For each path `compare` prints `same`, or
which of status, `Content-Type`, and body differ with a unified diff of
the body (split after each `>` and newline, since the pages are mostly on
one line; `--lines N` caps it, 40 by default). It exits non-zero when any
path differs. Redirects are not followed, so they are compared as they are.

## Deploying

```sh
make deploy
```

It deploys as the Worker `blog-moonbit`, apart from the Go `blog`, at
<https://blog-moonbit.ababjam61.workers.dev>.
