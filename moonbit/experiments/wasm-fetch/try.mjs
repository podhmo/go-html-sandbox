// `make try`: fetch through the Wasm on Node, once and twice in a request.
import { readFileSync } from "node:fs";
import { jspiApp } from "./adapter.mjs";

const app = jspiApp(new WebAssembly.Module(readFileSync("build/proxy.wasm")));
const r = await app.fetch(new Request("http://localhost/proxy?url=https://example.com/"));
console.log(r.status, await r.text());
const t = await app.fetch(new Request("http://localhost/twice"));
console.log(t.status, await t.text());
