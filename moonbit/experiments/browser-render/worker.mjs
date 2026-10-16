// `make dev-worker`: the same build/lib.wasm, imported into a Worker and
// called there. It answers with the imports workerd left and whether the
// instance could be made, and with what the baseline (the js build) gives.
import wasm from "./build/lib.wasm";
import { render as baseline } from "./build/lib.mjs";

export default {
  fetch() {
    const md = "# 見出し\n";
    const base = baseline(md);
    const imports = WebAssembly.Module.imports(wasm);
    try {
      const { render } = new WebAssembly.Instance(wasm, {}).exports;
      return Response.json({ imports: imports.length, html: render(md), baseline: base });
    } catch (e) {
      return Response.json({ imports: imports.length, error: String(e), baseline: base });
    }
  },
};
