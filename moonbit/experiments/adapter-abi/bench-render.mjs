// usage: node bench-render.mjs ; times Site::render alone inside the Wasm
// (bench.wasm) and with the JS string builtins (bench_js.wasm), without
// passing anything to the host.
import fs from "node:fs";
const opts = { builtins: ["js-string"], importedStringConstants: "wasm:js/string-constants" };
for (const name of ["bench", "bench_js"]) {
  const mod = new WebAssembly.Module(fs.readFileSync(`workers/build/${name}.wasm`), opts);
  const { bench } = new WebAssembly.Instance(mod, {}).exports;
  for (const big of [0, 1]) {
    for (let i = 0; i < 200; i++) bench(big);
    const runs = [];
    for (let r = 0; r < 5; r++) {
      const t = performance.now();
      for (let i = 0; i < 1000; i++) bench(big);
      runs.push(performance.now() - t);
    }
    runs.sort((a, b) => a - b);
    console.log(`${name}\t${big ? "largest" : "/"}\tmedian ${runs[2].toFixed(1)} µs`);
  }
}
