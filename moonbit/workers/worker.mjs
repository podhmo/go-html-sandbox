// The Worker around the MoonBit Wasm (../worker). Strings cross one UTF-16
// code unit at a time: the path through the exported path_push, the page
// back through the imported host.put. See
// docs/sketch/ja/moonbit-workers-wasm.md for why.
import wasm from "./build/app.wasm";

let out = [];
const instance = new WebAssembly.Instance(wasm, {
  host: { put: (code) => out.push(code) },
});

// render returns the page the Wasm renders for path.
function render(path) {
  out = [];
  for (let i = 0; i < path.length; i++) instance.exports.path_push(path.charCodeAt(i));
  instance.exports.serve();
  let s = "";
  // Spreading a huge array into fromCharCode would overflow the stack.
  for (let i = 0; i < out.length; i += 8192) s += String.fromCharCode(...out.slice(i, i + 8192));
  return s;
}

export default {
  async fetch(request) {
    let path;
    try {
      path = decodeURIComponent(new URL(request.url).pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    return new Response(render(path), {
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  },
};
