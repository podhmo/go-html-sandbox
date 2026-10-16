// The host side of the http/wasm package: runs a MoonBit Wasm that
// exports serve and memory (see wire.mbt) as a fetch handler, for
// Cloudflare Workers or anything else with the Fetch API's Request and
// Response, such as Node.
const encoder = new TextEncoder();
const decoder = new TextDecoder();
const noBody = new Uint8Array(0);
// Statuses whose Response must have a null body.
const nullBodyStatus = new Set([101, 103, 204, 205, 304]);

// wasmApp instantiates module and returns call, which answers a Request
// with the response's parts ({ status, headers, body }), and fetch, which
// answers it with a Response. env's string values cross as the request's
// env, like a Worker's variables and secrets.
export function wasmApp(module) {
  const { memory, serve } = new WebAssembly.Instance(module).exports;

  async function call(request, env = {}) {
    const body = request.body ? new Uint8Array(await request.arrayBuffer()) : noBody;
    let head = `${request.method}\n${request.url}\n`;
    for (const [name, value] of request.headers) head += `${name}\t${value}\n`;
    head += "\n";
    for (const [name, value] of Object.entries(env ?? {})) {
      if (typeof value === "string" && !/[\n\t]/.test(name) && !value.includes("\n")) {
        head += `${name}\t${value}\n`;
      }
    }
    head += "\n";
    // Room for the head at 3 bytes per UTF-16 code unit at most, and the body.
    const size = head.length * 3 + body.length;
    const more = Math.ceil(size / 65536) - memory.buffer.byteLength / 65536;
    if (more > 0) memory.grow(more);
    const { written } = encoder.encodeInto(head, new Uint8Array(memory.buffer));
    new Uint8Array(memory.buffer).set(body, written);
    // serve may grow the memory, which detaches the memory.buffer before it.
    const n = serve(written + body.length);
    const out = new Uint8Array(memory.buffer, 0, n);
    let end = out.indexOf(10);
    while (out[end + 1] !== 10) end = out.indexOf(10, end + 1);
    const [status, ...lines] = decoder.decode(out.subarray(0, end)).split("\n");
    const headers = lines.map((line) => {
      const tab = line.indexOf("\t");
      return [line.slice(0, tab), line.slice(tab + 1)];
    });
    return { status: +status, headers, body: out.slice(end + 2) };
  }

  return {
    call,
    async fetch(request, env) {
      return toResponse(await call(request, env));
    },
  };
}

// toResponse makes a Response of the parts call returns. It can be called
// again on the same parts.
export function toResponse({ status, headers, body }) {
  return new Response(nullBodyStatus.has(status) ? null : body, { status, headers });
}
