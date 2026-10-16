// `make try`: compile build/lib.wasm with and without the JS string
// builtins, and call render where it instantiates.
import { readFileSync } from "node:fs";
const bytes = readFileSync("build/lib.wasm");
const md = "# 見出し\n\n本文 `code` と [リンク](https://example.com) <b>esc</b>\n\n- a\n- b\n";

const plain = new WebAssembly.Module(bytes);
const left = WebAssembly.Module.imports(plain);
const count = (m) => left.filter((i) => i.module === m).length;
console.log(`without builtins: ${left.length} imports (${count("_")} from "_", ${count("wasm:js-string")} from "wasm:js-string")`);

const mod = new WebAssembly.Module(bytes, { builtins: ["js-string"], importedStringConstants: "_" });
console.log(`with builtins: ${WebAssembly.Module.imports(mod).length} imports`);
const { render } = new WebAssembly.Instance(mod, {}).exports;
const out = render(md);
console.log(`render: ${typeof out}: ${out}`);

// The baseline: the js build must give the same HTML.
const { render: baseline } = await import("./build/lib.mjs");
console.log(`baseline (js) gives the same HTML: ${baseline(md) === out}`);
