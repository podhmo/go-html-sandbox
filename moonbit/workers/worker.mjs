// The Worker around the MoonBit Wasm (../worker). The request and the
// response cross through the Wasm's memory as UTF-8: the request is
// "BASE_URL\nmethod\nquery\npath", with the path still percent-encoded,
// and serve writes the response over it, "status\nname\tvalue\n...\n\n"
// and the body. See
// docs/sketch/ja/moonbit-workers-adapter.md for why.
import wasm from "./build/app.wasm";

const { memory, serve } = new WebAssembly.Instance(wasm).exports;
const encoder = new TextEncoder();
const decoder = new TextDecoder();

export default {
  async fetch(request, env) {
    // The Wasm decodes the path, as Go's net/http does for the Go blog.
    const url = new URL(request.url);
    const req = `${env.BASE_URL ?? ""}\n${request.method}\n${url.search.slice(1)}\n${url.pathname}`;
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
    return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
  },
};
