// Runs the echo example's Wasm on Node through the adapter, with the same
// Request and Response as Workers: `make test` runs it.
import { readFileSync } from "node:fs";
import { test } from "node:test";
import assert from "node:assert/strict";
import { wasmApp } from "../../pkg/http/wasm/adapter.mjs";

// The Wasm as `moon build --target wasm-gc --release examples/echo` writes it.
const wasmURL = new URL("../../_build/wasm-gc/release/build/examples/echo/echo.wasm", import.meta.url);

const app = wasmApp(new WebAssembly.Module(readFileSync(wasmURL)));
const env = { GREETING: "hi", NOT_A_STRING: { a: 1 } };
const get = (path, init) => app.fetch(new Request(`http://localhost${path}`, init), env);

test("path wildcard and query", async () => {
  const res = await get("/hello/%E6%97%A5?greeting=hey+you");
  assert.equal(res.status, 200);
  assert.equal(await res.text(), "hey you, 日\n");
});

test("POST with a text body", async () => {
  const res = await get("/echo?a=1&a=2", { method: "POST", body: "日本語\n\nline", headers: { "content-type": "text/plain" } });
  assert.deepEqual(await res.json(), {
    method: "POST",
    host: "localhost",
    path: "/echo",
    query: [["a", "1"], ["a", "2"]],
    content_type: "text/plain",
    body: "日本語\n\nline",
    body_bytes: 15,
  });
});

test("JSON body", async () => {
  const res = await get("/json", { method: "POST", body: JSON.stringify({ x: [1, "y"] }) });
  assert.deepEqual(await res.json(), { got: { x: [1, "y"] } });
  const bad = await get("/json", { method: "POST", body: "{" });
  assert.equal(bad.status, 400);
});

test("urlencoded form", async () => {
  const body = new URLSearchParams([["name", "日本 語"], ["tag", "a"], ["tag", "b"]]);
  const res = await get("/form", { method: "POST", body });
  assert.deepEqual(await res.json(), { values: [["name", "日本 語"], ["tag", "a"], ["tag", "b"]], files: [] });
});

test("multipart form with a binary file", async () => {
  const form = new FormData();
  form.append("name", "multipart");
  const bytes = new Uint8Array(1000).map((_, i) => i % 256);
  form.append("file", new Blob([bytes], { type: "application/x-test" }), "a.bin");
  const res = await get("/form", { method: "POST", body: form });
  assert.deepEqual(await res.json(), {
    values: [["name", "multipart"]],
    files: [{ name: "file", filename: "a.bin", content_type: "application/x-test", size: 1000 }],
  });
});

test("a body larger than the memory's first page", async () => {
  const body = "x".repeat(200_000);
  const res = await get("/echo", { method: "PUT", body });
  assert.equal((await res.json()).body_bytes, 200_000);
});

test("a body over maxBodySize", async () => {
  const small = wasmApp(new WebAssembly.Module(readFileSync(wasmURL)), { maxBodySize: 10 });
  const at = (n) => small.fetch(new Request("http://localhost/echo", { method: "POST", body: "x".repeat(n) }));
  assert.equal((await (await at(10)).json()).body_bytes, 10);
  const res = await at(11);
  assert.equal(res.status, 413);
  // A stream without a Content-Length is cut off as well.
  const stream = new ReadableStream({ pull(c) { c.enqueue(new Uint8Array(8)); } });
  const res2 = await small.fetch(new Request("http://localhost/echo", { method: "POST", body: stream, duplex: "half" }));
  assert.equal(res2.status, 413);
});

test("methods", async () => {
  assert.equal((await get("/items/7", { method: "PUT", body: "v" })).status, 200);
  const del = await get("/items/7", { method: "DELETE" });
  assert.equal(del.status, 204);
  assert.equal(del.body, null);
  const res = await get("/items/7", { method: "GET" });
  assert.equal(res.status, 405);
  assert.equal(res.headers.get("allow"), "PUT, DELETE");
  assert.equal((await get("/nothing")).status, 404);
  assert.equal((await get("/%zz")).status, 400);
});

test("binary response, headers, redirect, env", async () => {
  const bytes = new Uint8Array(await (await get("/bytes")).arrayBuffer());
  assert.deepEqual([...bytes], [...Array(256).keys()]);
  const res = await get("/cookie", { headers: { cookie: "x=1" } });
  assert.equal(await res.text(), "cookie: x=1\n");
  assert.deepEqual(res.headers.getSetCookie(), ["a=1; Path=/", "b=2; Path=/"]);
  const r = await get("/redirect?to=/hello/x", { redirect: "manual" });
  assert.equal(r.status, 303);
  assert.equal(r.headers.get("location"), "/hello/x");
  assert.equal(await (await get("/env")).text(), "GREETING=hi\n");
});
