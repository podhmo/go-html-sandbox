# html-sandbox/moonbit

The blog reimplemented in [MoonBit](https://www.moonbitlang.com/), to run
on Cloudflare Workers as Wasm and compare its size with the Go builds.
It is an experiment in progress; see
[the research notes](../docs/sketch/ja/moonbit-workers-wasm.md) and
`TODO.md` for what is next.

- `site` — `render(path)`, returning the response for a path: status,
  headers, and body
- `worker` — the Wasm entry point: `path_push` and `serve` exported, the
  response sent back through the imported `host` functions (`status`,
  then `put` for text one UTF-16 code unit at a time, with `header_name`
  and `header_value` taking what was put as a header; the rest is the
  body)
- `workers` — the Cloudflare Worker: `worker.mjs` runs the Wasm for each
  request, and `wrangler.jsonc` builds it

Strings cross between JS and Wasm one code unit at a time because Workers
compiles imported Wasm modules without the JS string builtins, which
`use-js-builtin-string` relies on.

## Development

From `moonbit/` (`make help` lists the targets):

```sh
make test     # moon test
make build    # the Wasm, into _build/wasm-gc/release/build/worker/worker.wasm
make check    # before every commit: moon fmt --check, moon check, moon test
```

Needs `moon` on `PATH`, and Node.js for wrangler.

## Running on Workers locally

```sh
make dev            # or: make dev PORT=8798, if the Go Worker uses 8787
```

Then open <http://localhost:8787>. wrangler's build command runs
`moon build` and copies the Wasm to `workers/build/app.wasm`, ignored by
git, and `wrangler dev` rebuilds when `site/` or `worker/` changes.

## Deploying

```sh
make deploy
```

It deploys as the Worker `blog-moonbit`, apart from the Go `blog`, at
<https://blog-moonbit.ababjam61.workers.dev>.
