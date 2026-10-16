// `make concurrent`: three requests at once, each waiting on an upstream
// that answers /a after 300 ms and /b after 50 ms, and each must get its
// own answer. /c answers at the same time as /b, so two fetches resolve
// together.
import { readFileSync } from "node:fs";
import { createServer } from "node:http";
import { jspiApp } from "./adapter.mjs";

const delay = { "/a": 300, "/b": 50, "/c": 50 };
const up = createServer((req, res) => setTimeout(() => res.end(req.url), delay[req.url])).listen(8791);
await new Promise((r) => up.on("listening", r));
const app = jspiApp(new WebAssembly.Module(readFileSync("build/proxy.wasm")));
const go = (name, path) =>
  app.fetch(new Request(`http://localhost/slow/${name}?url=http://localhost:8791${path}`)).then((r) => r.text());
const got = await Promise.all([go("first", "/a"), go("second", "/b"), go("third", "/c")]);
console.log(got);
up.close();
const want = ["first 200 /a\n", "second 200 /b\n", "third 200 /c\n"];
if (JSON.stringify(got) !== JSON.stringify(want)) process.exit(1);
