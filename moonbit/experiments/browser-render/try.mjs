// `make try`: render the same Markdown through both builds on Node.
import { readFileSync } from "node:fs";
import { render } from "./build/lib.mjs";
const md = "# 見出し\n\n本文 `code` と [リンク](https://example.com) <b>esc</b>\n\n- a\n- b\n";
console.log("js  :", render(md));
const mod = new WebAssembly.Module(readFileSync("build/lib.wasm"), { builtins: ["js-string"], importedStringConstants: "_" });
console.log("imports:", JSON.stringify(WebAssembly.Module.imports(mod)));
const instance = new WebAssembly.Instance(mod, {});
console.log("wasm:", instance.exports.render(md));
