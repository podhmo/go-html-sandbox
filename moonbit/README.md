# html-sandbox/moonbit

The blog reimplemented in [MoonBit](https://www.moonbitlang.com/), to run
on Cloudflare Workers as Wasm and compare its size with the Go builds.
It is an experiment in progress; see
[the research notes](../docs/sketch/ja/moonbit-workers-wasm.md) and
`TODO.md` for what is next.

- `site` — `render(path)`, returning the HTML page for a path
- `worker` — the Wasm entry point: `path_push` and `serve` exported, the
  page sent back through the imported `host.put`, one UTF-16 code unit at
  a time

Strings cross between JS and Wasm one code unit at a time because Workers
compiles imported Wasm modules without the JS string builtins, which
`use-js-builtin-string` relies on.

## Development

From `moonbit/`:

```sh
moon test                               # tests of site
moon build --target wasm-gc --release   # _build/wasm-gc/release/build/worker/worker.wasm
moon fmt                                # format the sources
```
