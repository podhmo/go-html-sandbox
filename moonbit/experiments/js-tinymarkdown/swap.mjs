// A Vite plugin that resolves every import of the TS port of tinymarkdown
// (ts/pkg/tinymarkdown/tinymarkdown.ts), relative or not, to tinymarkdown.ts
// here, over the MoonBit build. The importer must not be this directory's
// own tinymarkdown.ts, whose type imports name the TS port.
import { resolve } from "node:path";

const port = resolve(import.meta.dirname, "../../../ts/pkg/tinymarkdown/tinymarkdown.ts");
const shim = resolve(import.meta.dirname, "tinymarkdown.ts");

export function swapTinymarkdown() {
  return {
    name: "swap-tinymarkdown",
    enforce: "pre",
    async resolveId(source, importer, options) {
      if (!source.endsWith("tinymarkdown.ts") || importer === shim) return null;
      const r = await this.resolve(source, importer, { ...options, skipSelf: true });
      return r?.id === port ? shim : null;
    },
  };
}
