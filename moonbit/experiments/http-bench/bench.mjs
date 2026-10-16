// usage: node bench.mjs <name>...
// Times the blog's Wasm in build/<name>.wasm through its own commit's
// adapter: "pr31" through PR #31's worker.mjs (reimplemented below, as it
// imported the Wasm), anything else through ../../http/wasm/adapter.mjs.
// Checks first that every variant answers / and the largest page alike.
import { readFileSync } from "node:fs";
import { wasmApp } from "../../http/wasm/adapter.mjs";

const env = { BASE_URL: "https://blog.podhmo.workers.dev" };
const encoder = new TextEncoder();
const decoder = new TextDecoder();

// pr31App is PR #31's render() of moonbit/workers/worker.mjs, without its cache.
function pr31App(mod) {
  const { memory, serve } = new WebAssembly.Instance(mod).exports;
  return {
    async fetch(request, env) {
      const url = new URL(request.url);
      const req = `${env.BASE_URL}\n${request.method}\n${url.search.slice(1)}\n${url.pathname}`;
      const more = Math.ceil((req.length * 3) / 65536) - memory.buffer.byteLength / 65536;
      if (more > 0) memory.grow(more);
      const { written } = encoder.encodeInto(req, new Uint8Array(memory.buffer));
      const n = serve(written);
      const out = new Uint8Array(memory.buffer, 0, n);
      let end = out.indexOf(10);
      while (out[end + 1] !== 10) end = out.indexOf(10, end + 1);
      const [status, ...headers] = decoder.decode(out.subarray(0, end)).split("\n");
      return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
    },
  };
}

const names = process.argv.slice(2);
const apps = Object.fromEntries(
  names.map((name) => {
    const mod = new WebAssembly.Module(readFileSync(`build/${name}.wasm`));
    return [name, name === "pr31" ? pr31App(mod) : wasmApp(mod)];
  }),
);
const paths = ["/", "/docs/sketch/ja/moonbit-modernize"];
const request = (p) => new Request("http://localhost:8787" + p, { headers: { "user-agent": "bench", accept: "text/html" } });
for (const p of paths) {
  const got = await Promise.all(Object.values(apps).map(async (app) => {
    const r = await app.fetch(request(p), env);
    return r.status + (await r.text());
  }));
  if (new Set(got).size !== 1) throw new Error(`the variants answer ${p} differently`);
}
for (let round = 0; round < 2; round++) {
  for (const [name, app] of Object.entries(apps)) {
    for (const p of paths) {
      const times = [];
      for (let k = 0; k < 5; k++) {
        const t = performance.now();
        for (let i = 0; i < 1000; i++) await (await app.fetch(request(p), env)).arrayBuffer();
        times.push(performance.now() - t); // ms per 1,000 = µs per request
      }
      times.sort((x, y) => x - y);
      console.log(`${round}\t${name}\t${p}\t${times[2].toFixed(1)} µs`);
    }
  }
}
