// The Worker around the MoonBit Wasm (../worker), run by the adapter of
// ../http/wasm, which passes the request and the response through the
// Wasm's memory. See docs/sketch/ja/moonbit-workers-adapter.md and
// docs/sketch/ja/moonbit-workers-http.md for why.
import wasm from "./build/app.wasm";
import { wasmApp, toResponse } from "../http/wasm/adapter.mjs";

const app = wasmApp(wasm);

// cache holds the 200 responses to GET and HEAD by path, for this isolate.
// The content is embedded in the Wasm, so a path's page never changes, and
// the query only matters to redirects. Spelling a path with different
// escapes makes a new key, so the cache starts over when it is full.
const cache = new Map();
const cacheLimit = 1024;
let cachedBaseURL;

export default {
  async fetch(request, env) {
    const baseURL = env.BASE_URL ?? "";
    if (baseURL !== cachedBaseURL || cache.size >= cacheLimit) {
      cache.clear();
      cachedBaseURL = baseURL;
    }
    const cacheable = request.method === "GET" || request.method === "HEAD";
    const path = cacheable ? new URL(request.url).pathname : undefined;
    let res = cacheable ? cache.get(path) : undefined;
    if (!res) {
      res = await app.call(request, env);
      if (cacheable && res.status === 200) cache.set(path, res);
    }
    return toResponse(res);
  },
};
