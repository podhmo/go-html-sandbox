// The Worker around the MoonBit Wasm (../worker). The request and the
// response cross through the Wasm's memory as UTF-8: the request is
// "BASE_URL\nmethod\nquery\npath", with the path still percent-encoded,
// and serve writes the response over it, "status\nname\tvalue\n...\n\n"
// and the body. See docs/sketch/ja/moonbit-workers-adapter.md for why.
import wasm from "./build/app.wasm";

const { memory, serve } = new WebAssembly.Instance(wasm).exports;
const encoder = new TextEncoder();
const decoder = new TextDecoder();

// render runs the Wasm for one request and returns the response's parts.
function render(baseURL, method, query, path) {
  const req = `${baseURL}\n${method}\n${query}\n${path}`;
  // Room for the request at 3 bytes per UTF-16 code unit at most.
  const more = Math.ceil((req.length * 3) / 65536) - memory.buffer.byteLength / 65536;
  if (more > 0) memory.grow(more);
  const { written } = encoder.encodeInto(req, new Uint8Array(memory.buffer));
  // serve may grow the memory, which detaches the memory.buffer before it.
  const n = serve(written);
  const out = new Uint8Array(memory.buffer, 0, n);
  let end = out.indexOf(10);
  while (out[end + 1] !== 10) end = out.indexOf(10, end + 1);
  const [status, ...headers] = decoder.decode(out.subarray(0, end)).split("\n");
  return { status: +status, headers: headers.map((h) => h.split("\t")), body: out.slice(end + 2) };
}

// cache holds the 200 responses to GET and HEAD by path, for this isolate.
// The content is embedded in the Wasm, so a path's page never changes, and
// the query only matters to redirects. Spelling a path with different
// escapes makes a new key, so the cache starts over when it is full.
const cache = new Map();
const cacheLimit = 1024;
let cachedBaseURL;

export default {
  async fetch(request, env) {
    // The Wasm decodes the path, as Go's net/http does for the Go blog.
    const url = new URL(request.url);
    const baseURL = env.BASE_URL ?? "";
    const cacheable = request.method === "GET" || request.method === "HEAD";
    if (baseURL !== cachedBaseURL || cache.size >= cacheLimit) {
      cache.clear();
      cachedBaseURL = baseURL;
    }
    let res = cacheable ? cache.get(url.pathname) : undefined;
    if (!res) {
      res = render(baseURL, request.method, url.search.slice(1), url.pathname);
      if (cacheable && res.status === 200) cache.set(url.pathname, res);
    }
    return new Response(res.body, res);
  },
};
