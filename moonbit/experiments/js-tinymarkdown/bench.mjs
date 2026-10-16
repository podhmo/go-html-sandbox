// Times parse, and inlines over every paragraph, on the posts, TODO.md, and
// docs/**/*.md, for the TS port and the MoonBit build, and MoonBit's parse without
// building the JS objects. Usage: node bench.mjs
import { readFileSync, globSync } from "node:fs";
import { isDeepStrictEqual } from "node:util";
import * as ts from "../../../ts/pkg/tinymarkdown/tinymarkdown.ts";
import * as mb from "./build/tinymarkdown.mjs";

const root = `${import.meta.dirname}/../../..`;
const files = [...globSync("posts/*.md", { cwd: root }), "TODO.md", ...globSync("docs/**/*.md", { cwd: root })];
const srcs = files.map((f) => readFileSync(`${root}/${f}`, "utf8"));
const bytes = srcs.reduce((n, s) => n + Buffer.byteLength(s), 0);

function texts(blocks, out = []) {
  for (const b of blocks) {
    if (b.kind === "paragraph") out.push(b.text);
    if (b.kind === "section") out.push(b.title);
    if (b.children) texts(b.children, out);
  }
  return out;
}
const paras = srcs.flatMap((s) => texts(ts.parse(s).children));

for (const s of srcs) if (!isDeepStrictEqual(ts.parse(s), mb.parse(s))) throw new Error("parse differs");
for (const p of paras) if (!isDeepStrictEqual(ts.inlines(p), mb.inlines(p))) throw new Error("inlines differs");
console.log(`${files.length} files, ${(bytes / 1024).toFixed(0)} KiB, ${paras.length} paragraphs and titles; results equal`);

function time(name, f) {
  const t0 = performance.now();
  f();
  const first = performance.now() - t0;
  for (let i = 0; i < 20; i++) f();
  const n = 50;
  const t1 = performance.now();
  for (let i = 0; i < n; i++) f();
  console.log(`${name.padEnd(18)} first ${first.toFixed(2)} ms, warm ${((performance.now() - t1) / n).toFixed(2)} ms`);
}
for (const [name, m] of [["ts", ts], ["moonbit", mb]]) {
  time(`${name} parse`, () => srcs.forEach((s) => m.parse(s)));
  time(`${name} inlines`, () => paras.forEach((p) => m.inlines(p)));
}
// MoonBit's parse alone, without building the JS objects.
time("moonbit parse_only", () => srcs.forEach((s) => mb.parse_only(s)));
