# html-sandbox/ts

The blog written the plain way for Cloudflare Workers: TypeScript,
[Hono](https://hono.dev/), and `hono/jsx`, with no Wasm. It is here to see
how much the Go and MoonBit builds pay for being Wasm; see
[the notes](../docs/sketch/ja/ts-hono-workers.md).

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
- `src/content.ts` — loading the posts and documents, with the Go blog's
  checks (file names, duplicate slugs, titles, front matter keys)
- `src/links.ts` — resolving the URLs of Markdown links, as the Go blog does
- `scripts/embed.ts` — writes the posts, `TODO.md`, and `docs/**/*.md` into
  `src/content.gen.json`, which the Worker imports, and copies the Go blog's
  `site.css` and `favicon.svg` into `public/`, which Workers serves as
  static assets (`public/_headers` sets their `Cache-Control`); wrangler
  runs it before every build
- `wrangler.jsonc` — deploys as `blog-ts`, beside the Go and MoonBit blogs

## Running

Node 24 or later, which runs `.ts` files as they are (not `.tsx`):

```sh
npm install
npm run dev      # wrangler dev on http://localhost:8787
npm run check    # embed, the tests (vitest), and tsc --noEmit
npm run deploy   # wrangler deploy
```

There is no Makefile: npm scripts are enough. The tests run with vitest
rather than `node --test` because Node cannot load `.tsx`.
