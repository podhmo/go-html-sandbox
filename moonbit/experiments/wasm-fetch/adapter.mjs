// The host side of the spike: runs the Wasm (./proxy) as a fetch handler,
// and lets it await the host's fetch through JSPI. host.fetch is wrapped in
// WebAssembly.Suspending, so the Wasm's stack waits for it, and serve in
// WebAssembly.promising, so calling it gives a Promise.
//
// While one request waits, another can enter serve and use address 0 of the
// memory, so nothing is written there across a wait: the request is read
// before the first wait, a fetch's result is kept here under a ticket until
// host.take, which does not suspend, copies it in, and the response is
// copied out by host.done, which does not suspend either.
const encoder = new TextEncoder();
const decoder = new TextDecoder();

export function jspiApp(module) {
  let memory;
  let nextId = 0;
  const results = new Map(); // ticket -> the fetch's result
  const responses = new Map(); // request id -> the response's bytes
  const imports = {
    host: {
      fetch: new WebAssembly.Suspending(async (n) => {
        const url = decoder.decode(new Uint8Array(memory.buffer, 0, n));
        const res = await fetch(url);
        const ticket = nextId++;
        results.set(ticket, encoder.encode(`${res.status}\n${await res.text()}`));
        return ticket;
      }),
      take: (ticket) => {
        const result = results.get(ticket);
        results.delete(ticket);
        const more = Math.ceil(result.length / 65536) - memory.buffer.byteLength / 65536;
        if (more > 0) memory.grow(more);
        new Uint8Array(memory.buffer).set(result);
        return result.length;
      },
      done: (id, n) => {
        responses.set(id, new Uint8Array(memory.buffer, 0, n).slice());
      },
    },
  };
  const instance = new WebAssembly.Instance(module, imports);
  memory = instance.exports.memory;
  const serve = WebAssembly.promising(instance.exports.serve);
  return {
    async fetch(request) {
      // Only the method and the URL: the spike has no headers or body.
      const head = `${request.method}\n${request.url}\n\n\n`;
      const { written } = encoder.encodeInto(head, new Uint8Array(memory.buffer));
      const id = nextId++;
      await serve(id, written);
      const out = responses.get(id);
      responses.delete(id);
      let end = out.indexOf(10);
      while (out[end + 1] !== 10) end = out.indexOf(10, end + 1);
      const [status, ...lines] = decoder.decode(out.subarray(0, end)).split("\n");
      const headers = lines.map((line) => [line.slice(0, line.indexOf("\t")), line.slice(line.indexOf("\t") + 1)]);
      return new Response(out.slice(end + 2), { status: +status, headers });
    },
  };
}
