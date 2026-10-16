// usage: node bench.mjs <workers dir> <variant>... ; loads worker-<v>.mjs with
// its wasm import replaced, checks outputs match v[0], and times paths.
import fs from "node:fs";
import path from "node:path";
const dir = process.argv[2];
const variants = process.argv.slice(3);
const env = { BASE_URL: "https://blog.podhmo.workers.dev" };
async function load(v) {
  const src = fs.readFileSync(path.join(dir, `worker-${v}.mjs`), "utf8");
  const m = src.match(/import wasm from "\.\/build\/(.*?)";/);
  globalThis.__wasm = new WebAssembly.Module(fs.readFileSync(path.join(dir, "build", m[1])), { builtins: ["js-string"], importedStringConstants: "wasm:js/string-constants" });
  fs.mkdirSync(".gen", { recursive: true });
  const tmp = path.join(process.cwd(), ".gen", `gen-${v}.mjs`);
  fs.writeFileSync(tmp, src.replace(m[0], "const wasm = globalThis.__wasm;"));
  return (await import(tmp + "?" + Date.now())).default;
}
const workers = {};
for (const v of variants) workers[v] = await load(v);
async function get(w, p, method = "GET") {
  const res = await w.fetch(new Request("http://localhost" + p, { method }), env);
  const body = new Uint8Array(await res.arrayBuffer());
  return { status: res.status, headers: [...res.headers].join("|"), body };
}
// paths: everything linked from / and /docs/
const base = workers[variants[0]];
const seen = new Set(["/", "/docs/", "/docs", "/favicon.svg", "/site.css", "/no-such", "/posts/nope", "/docs/a%3Cb%3E", "/%E6%97%A5%E6%9C%AC"]);
for (const p of ["/", "/docs/"]) {
  const html = new TextDecoder().decode((await get(base, p)).body);
  for (const m of html.matchAll(/href="(\/(?:posts|docs)\/[^"#?]+)"/g)) { seen.add(m[1]); seen.add(m[1] + ".md"); }
}
const paths = [...seen];
let largest = paths[0], size = 0;
for (const p of paths) {
  const r0 = await get(base, p);
  if (r0.body.length > size) { size = r0.body.length; largest = p; }
  for (const v of variants.slice(1)) {
    const r = await get(workers[v], p);
    const same = r.status === r0.status && r.headers === r0.headers && Buffer.compare(Buffer.from(r.body), Buffer.from(r0.body)) === 0;
    if (!same) console.log("DIFF", v, p, r0.status, r.status, r0.headers, r.headers, r0.body.length, r.body.length);
  }
}
console.log(`${paths.length} paths compared; largest ${largest} ${size} B`);
const N = +(process.env.N ?? 2000);
for (const p of ["/", largest]) {
  for (const v of variants) {
    const w = workers[v];
    for (let i = 0; i < 200; i++) await get(w, p);
    const runs = [];
    for (let r = 0; r < 5; r++) {
      const t = performance.now();
      for (let i = 0; i < N; i++) await get(w, p);
      runs.push(((performance.now() - t) / N) * 1000);
    }
    runs.sort((a, b) => a - b);
    console.log(`${p}\t${v}\tmedian ${runs[2].toFixed(1)} µs/req (min ${runs[0].toFixed(1)}, max ${runs[4].toFixed(1)})`);
  }
}
