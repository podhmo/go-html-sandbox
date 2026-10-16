# moonbit/experiments

Spikes kept so that their numbers can be reproduced. Each directory with
a `moon.mod` is a module of its own, outside the blog's module, so the
blog's `make check` and `make build` do not see it; its `moon.work` adds
the blog (`../..`) as a workspace member, so it imports `podhmo/html-sandbox/...`
as it is now. The code was adjusted to today's API where it had to be,
and is otherwise as it was tried. Run `make help` in each directory.

| Directory | What | Notes |
| --- | --- | --- |
| `adapter-abi` | The ways of passing the request and the response between JS and the Wasm that PR #31 compared: one UTF-16 code unit per call (`v0`, the adapter before), eight per call (`packed`), the linear memory in UTF-16 (`mem16`) or UTF-8 (`utf8enc`, `utf8d`), and the JS string builtins (`jsstr`); `bench` and `bench_js` time `Site::render` alone | [moonbit-workers-adapter.md](../../docs/sketch/ja/moonbit-workers-adapter.md) |
| `http-bench` | The blog's Wasm at PR #31's last commit and after the http library, built from git, timed through their adapters; and the stub app of `pkg/http/wasm/integration` with headers and bodies of each size | [moonbit-workers-http.md](../../docs/sketch/ja/moonbit-workers-http.md) |
| `wasm-fetch` | Awaiting the host's `fetch` from the Wasm through JSPI (`WebAssembly.Suspending` and `promising`), on Node and with wrangler, with concurrent requests | [moonbit-workers-http.md](../../docs/sketch/ja/moonbit-workers-http.md) |
| `browser-render` | Calling tinymarkdown and el from the browser: a `render` built for js and for wasm-gc (with the JS string builtins), and an editor page that previews the Markdown as it is typed; Chrome runs both. In a Worker the js build runs as it is, but the wasm-gc one does not instantiate, as workerd compiles an imported Wasm without the builtins | [moonbit-browser-render.md](../../docs/sketch/ja/moonbit-browser-render.md) |

`adapter-abi` builds every variant against the blog as it is now, so its
pages, and with them the sizes, are not those in the notes; the order of
the timings is what to compare.
