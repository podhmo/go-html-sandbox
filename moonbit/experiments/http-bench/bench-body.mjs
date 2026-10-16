// usage: node bench-body.mjs (after make -C ../.. build-echo)
// Times the echo example with request headers and bodies of each size.
import { readFileSync } from "node:fs";
import { wasmApp } from "../../http/wasm/adapter.mjs";
const app = wasmApp(new WebAssembly.Module(readFileSync("../../examples/echo/build/echo.wasm")));
const browser = { "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36", accept: "text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8", "accept-language": "ja,en-US;q=0.9,en;q=0.8", "accept-encoding": "gzip, deflate, br, zstd", cookie: "a=".padEnd(300, "x"), "sec-ch-ua": "\"Chromium\";v=\"141\"", "sec-fetch-mode": "navigate", "sec-fetch-site": "none", "upgrade-insecure-requests": "1" };
async function bench(label, mk, count = 1000) {
  const times = [];
  for (let k = 0; k < 5; k++) { const t = performance.now(); for (let i = 0; i < count; i++) { const r = await app.fetch(mk()); await r.arrayBuffer(); } times.push((performance.now() - t) * 1000 / count); }
  times.sort((a, b) => a - b); console.log(label, times[2].toFixed(1), "µs");
}
await bench("GET /hello/x, no headers", () => new Request("http://localhost/hello/x"));
await bench("GET /hello/x, browser headers", () => new Request("http://localhost/hello/x", { headers: browser }));
for (const size of [1_000, 100_000, 1_000_000]) {
  const body = new Uint8Array(size);
  await bench(`PUT /items/1 ${size} B (text)`, () => new Request("http://localhost/items/1", { method: "PUT", body }), size >= 1e6 ? 20 : 200);
  await bench(`POST /echo ${size} B (echoed back in JSON)`, () => new Request("http://localhost/echo", { method: "POST", body }), size >= 1e6 ? 20 : 200);
}
for (const size of [100_000, 1_000_000]) {
  const body = new Uint8Array(size);
  await bench(`POST /hello/x ${size} B (405, body only copied in)`, () => new Request("http://localhost/hello/x", { method: "POST", body }), 20);
}
