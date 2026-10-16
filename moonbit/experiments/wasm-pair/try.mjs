// `make try`: the two Wasm modules on Node, joined both ways that run on
// one thread: JS passing parser's output to html, and linked calling
// html's render through its import.
import { readFileSync } from "node:fs";

const options = { builtins: ["js-string"], importedStringConstants: "_" };
const compile = (name) => new WebAssembly.Module(readFileSync(`build/${name}.wasm`), options);
const md = "# 見出し\n\n本文 `code` と [リンク](https://example.com) <b>esc</b>\n\n- a\n  - a-1\n- b\n";

const parser = new WebAssembly.Instance(compile("parser"), {}).exports;
const html = new WebAssembly.Instance(compile("html"), {}).exports;
const json = parser.parse(md);
console.log(`parser.parse: ${json}`);
const viaJS = html.render(json);
console.log(`html.render(parser.parse(md)): ${viaJS}`);

const linkedModule = compile("linked");
console.log(`linked imports: ${JSON.stringify(WebAssembly.Module.imports(linkedModule))}`);
const linked = new WebAssembly.Instance(linkedModule, { html: { render: html.render } }).exports;
const direct = linked.preview(md);
console.log(`linked.preview(md) is the same: ${direct === viaJS}`);
