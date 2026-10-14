// The Worker around the MoonBit Wasm (../worker). Strings cross one UTF-16
// code unit at a time: the path through the exported path_push, the
// response back through the imported host functions below. See
// docs/sketch/ja/moonbit-workers-wasm.md for why.
import wasm from "./build/app.wasm";

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
    status: (code) => (res.status = code),
    header_name: () => (name = take()),
    header_value: () => res.headers.append(name, take()),
  },
});

// serve returns the response the Wasm builds for path.
function serve(path) {
  res = { status: 200, headers: new Headers() };
  buf = [];
  for (let i = 0; i < path.length; i++) instance.exports.path_push(path.charCodeAt(i));
  instance.exports.serve();
  return new Response(take(), res);
}

export default {
  async fetch(request) {
    let path;
    try {
      path = decodeURIComponent(new URL(request.url).pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    return serve(path);
  },
};
