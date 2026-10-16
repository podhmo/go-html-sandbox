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
| `browser-render` | Whether the wasm-gc build alone, with no JS that MoonBit generates, runs tinymarkdown and el in the browser: a `render` built with the JS string builtins, and an editor page that previews the Markdown as it is typed. It runs in Chrome and from Static Assets; the same `.wasm` does not instantiate inside a Worker, as workerd compiles an imported Wasm without the builtins. The js build is only the baseline | [moonbit-browser-render.md](../../docs/sketch/ja/moonbit-browser-render.md) |
| `wasm-pair` | Two wasm-gc modules talking in the browser: `parser.wasm` (Markdown to JSON) and `html.wasm` (JSON to HTML), joined on one thread (through JS, or `linked.wasm` importing `html.wasm`'s `render`) and as two Workers over a MessagePort; `make check-browser` times how long each way stops the page on a large document | [moonbit-wasm-pair.md](../../docs/sketch/ja/moonbit-wasm-pair.md) |

`adapter-abi` builds every variant against the blog as it is now, so its
pages, and with them the sizes, are not those in the notes; the order of
the timings is what to compare.
