# html-sandbox/ts

The blog written the plain way for Cloudflare Workers: TypeScript,
[Hono](https://hono.dev/), and `hono/jsx`, with no Wasm, set up as Hono's
[Cloudflare Workers + Vite](https://hono.dev/docs/getting-started/cloudflare-workers-vite)
template. It is here to see how much the Go and MoonBit builds pay for
being Wasm; see [the notes](../docs/sketch/ja/ts-hono-workers.md).

Only the Markdown and front matter parsers are ported from `../go`; the
pages are TSX, so there is no port of `el` or `picoel`.

`pkg/`:

- `tinymarkdown` — a port of `go/pkg/tinymarkdown`: `parse(src)` into a
  tree of sections, paragraphs, lists, quotes, tables, and code blocks, and
  `inlines(text)` into text, code spans, and links; its tests are the Go
  test cases
- `tinyfrontmatter` — a port of `go/pkg/tinyfrontmatter`: `split(src)`
  into the `key: value` pairs of a leading `---` block and the rest; its
  tests are the Go test cases

`examples/blog/`, the blog:

- `src/app.tsx` — the Hono app and the Worker's entry point: the routes of
  the Go blog (`/`, `/posts/{slug}` and `/docs/{path}` with their `.md`
  sources, `/docs/`, and the 404 and 500 pages)
- `src/views.tsx` — the pages in TSX, the layout as a `jsxRenderer`
- `src/sources.ts` — imports the posts, `TODO.md`, and `docs/**/*.md` as
  text with `import.meta.glob`, and the Go blog's `site.css` and
  `favicon.svg` as asset URLs, which Vite gives a hash of their content
- `src/content.ts` — loading the posts and documents, with the Go blog's
  checks (file names, duplicate slugs, titles, front matter keys)
- `src/links.ts` — resolving the URLs of Markdown links, as the Go blog does
- `public/_headers` — `Cache-Control` for the hashed assets
- `vite.config.ts` and `wrangler.jsonc` — the Cloudflare plugin for Vite,
  and the Worker, which deploys as `blog-ts`, beside the Go and MoonBit
  blogs

## Running

Node 24 or later:

```sh
npm install
npm run dev      # vite: the Worker in workerd on http://localhost:5173
npm run check    # the tests (vitest) and tsc --noEmit
npm run build    # vite build into examples/blog/dist/
npm run preview  # build, and serve dist/ as it would be deployed
npm run deploy   # build, and wrangler deploy
```

`npm run dev` picks up edits to the posts and documents, `TODO.md` too, on
the next request. There is no Makefile: npm scripts are enough.
