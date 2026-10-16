// The Worker around the MoonBit Wasm (../worker), built with
// use-js-builtin-string: strings cross as JS strings, which needs the
// wasm_esm_integration_builtins compatibility flag. serve returns
// "status\nname\tvalue\n...\n\n" followed by the body.
import wasm from "./build/jsstr-Oz.wasm";

const { serve } = new WebAssembly.Instance(wasm).exports;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    let path;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    const out = serve(env.BASE_URL ?? "", request.method, path, url.search.slice(1));
    const end = out.indexOf("\n\n");
    const [status, ...headers] = out.slice(0, end).split("\n");
    return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
  },
};
