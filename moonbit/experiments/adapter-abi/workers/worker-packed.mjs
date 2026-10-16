// The Worker around the MoonBit Wasm (../worker). Strings cross one UTF-16
// code unit at a time: the path (and once, BASE_URL) through the exported
// path_push, the response back through the imported host functions below. See
// docs/sketch/ja/moonbit-workers-wasm.md for why.
import wasm from "./build/packed.wasm";

// res is the response serve is building; buf holds the code units put
// since the last header_name or header_value.
let res, buf, name;

function take() {
  let s = "";
  // Spreading a huge array into fromCharCode would overflow the stack.
  for (let i = 0; i < buf.length; i += 8192) s += String.fromCharCode(...buf.slice(i, i + 8192));
  buf = [];
  return s;
}

const instance = new WebAssembly.Instance(wasm, {
  host: {
    put: (code) => buf.push(code),
    put8: (a, b, c, d) => buf.push(a & 0xffff, a >>> 16, b & 0xffff, b >>> 16, c & 0xffff, c >>> 16, d & 0xffff, d >>> 16),
    status: (code) => (res.status = code),
    header_name: () => (name = take()),
    header_value: () => res.headers.append(name, take()),
  },
});

function push(s) {
  for (let i = 0; i < s.length; i++) instance.exports.path_push(s.charCodeAt(i));
}

// baseURL is the BASE_URL given to the Wasm, which it reads once.
let baseURL;

// serve returns the response the Wasm builds for path and query, the
// raw query string without "?", which only redirects keep.
function serve(path, query) {
  res = { status: 200, headers: new Headers() };
  buf = [];
  if (query !== "") {
    push(query);
    instance.exports.set_query();
  }
  push(path);
  instance.exports.serve();
  return new Response(take(), res);
}

export default {
  async fetch(request, env) {
    if (baseURL !== env.BASE_URL) {
      baseURL = env.BASE_URL;
      push(baseURL ?? "");
      instance.exports.set_base_url();
    }
    const url = new URL(request.url);
    let path;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    return serve(path, url.search.slice(1));
  },
};
