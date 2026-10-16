// embed writes what the Worker serves into this directory, as the Go blog's
// `go generate` copies it in:
//
//   - src/content.gen.json: the posts (posts/*.md in the repository root)
//     and the repository's own documents (TODO.md and docs/**/*.md), which
//     the Worker imports, and the hash of site.css for its URL
//   - public/: the Go blog's site.css and favicon.svg, served by Workers
//     as static assets
//
// Run it with Node 24 or later, which runs .ts files as they are:
// `node scripts/embed.ts`. wrangler runs it before every build.
import { createHash } from "node:crypto";
import { copyFileSync, globSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const here = join(import.meta.dirname, "..");
const repo = join(here, "../../..");
const assets = join(repo, "go/examples/blog/internal/site");

const read = (path: string) => readFileSync(join(repo, path), "utf8");
const files = (pattern: string) => globSync(pattern, { cwd: repo }).sort();

const posts = files("posts/*.md").map((path) => ({ file: path.slice("posts/".length), markdown: read(path) }));
const docs = ["TODO.md", ...files("docs/**/*.md")].map((source) => ({ source, markdown: read(source) }));
const siteCSS = readFileSync(join(assets, "site.css"));
const siteCSSHash = createHash("sha256").update(siteCSS).digest("hex").slice(0, 8);

writeFileSync(join(here, "src/content.gen.json"), JSON.stringify({ posts, docs, siteCSSHash }, null, 1) + "\n");
mkdirSync(join(here, "public"), { recursive: true });
for (const name of ["site.css", "favicon.svg"]) copyFileSync(join(assets, name), join(here, "public", name));
console.log(`embed: ${posts.length} posts, ${docs.length} docs, site.css ${siteCSSHash}`);
