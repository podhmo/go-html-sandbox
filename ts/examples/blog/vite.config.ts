// Vite with the Cloudflare plugin, as Hono's cloudflare-workers+vite
// template: `vite` runs the Worker in workerd, `vite build` bundles it and
// its assets into dist/, and `wrangler deploy` deploys dist/.
import { cloudflare } from "@cloudflare/vite-plugin";
import { resolve } from "node:path";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [cloudflare()],
  // The posts, the documents, and site.css sit in the repository root,
  // outside this project, where Vite does not read files by default.
  server: { fs: { allow: [resolve(import.meta.dirname, "../../..")] } },
  // Serve favicon.svg as a file, as the Go blog does, rather than inline
  // it into every page as a data: URL.
  build: { assetsInlineLimit: 0 },
});
