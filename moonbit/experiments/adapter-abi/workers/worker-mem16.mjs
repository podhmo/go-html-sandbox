// The Worker around the MoonBit Wasm (../worker). The request goes into
// the Wasm's memory as UTF-16, "BASE_URL\nmethod\nquery\npath", and serve
// writes the response over it: "status\nname\tvalue\n...\n\n" and the body.
import wasm from "./build/mem16.wasm";

const { memory, serve } = new WebAssembly.Instance(wasm).exports;
const decoder = new TextDecoder("utf-16le");

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    let path;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    const req = `${env.BASE_URL ?? ""}\n${request.method}\n${url.search.slice(1)}\n${path}`;
    const more = Math.ceil((req.length * 2) / 65536) - memory.buffer.byteLength / 65536;
    if (more > 0) memory.grow(more);
    const in16 = new Uint16Array(memory.buffer, 0, req.length);
    for (let i = 0; i < req.length; i++) in16[i] = req.charCodeAt(i);
    const n = serve(req.length);
    const out = decoder.decode(new Uint16Array(memory.buffer, 0, n));
    const end = out.indexOf("\n\n");
    const [status, ...headers] = out.slice(0, end).split("\n");
    return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
  },
};
