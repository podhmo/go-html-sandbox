// What the blog serves, imported through Vite: the posts (posts/*.md in the
// repository root), the repository's own documents (TODO.md and
// docs/**/*.md) as text, and the Go blog's site.css and favicon.svg as the
// URLs of assets, with a hash of their content in the file name.
import siteCSS from "../../../../go/examples/blog/internal/site/site.css?url";
import favicon from "../../../../go/examples/blog/internal/site/favicon.svg?url";

export { favicon, siteCSS };

const root = "../../../../";

const raw = (files: Record<string, string>) =>
  Object.entries(files)
    .map(([path, markdown]) => ({ path: path.slice(root.length), markdown }))
    .sort((a, b) => a.path.localeCompare(b.path));

export const posts = raw(import.meta.glob("../../../../posts/*.md", { query: "?raw", import: "default", eager: true })).map(
  ({ path, markdown }) => ({ file: path.slice("posts/".length), markdown }),
);

export const docs = raw(
  import.meta.glob(["../../../../TODO.md", "../../../../docs/**/*.md"], { query: "?raw", import: "default", eager: true }),
)
  .sort((a, b) => Number(b.path === "TODO.md") - Number(a.path === "TODO.md"))
  .map(({ path, markdown }) => ({ source: path, markdown }));
