# html-sandbox

Experiments with classic server-side rendered HTML, implemented in more
than one language.

- [`go/`](go/README.md) — the Go standard library only: an HTML builder,
  a tiny Markdown parser, and a blog built on them
- [`moonbit/`](moonbit/README.md) — the blog in MoonBit, as Wasm for
  Cloudflare Workers (an experiment in progress)
- [`ts/`](ts/README.md) — the blog written the plain way for Workers, in
  TypeScript with Hono and `hono/jsx`, without Wasm, to compare with the
  Wasm builds

Shared across implementations:

- [`posts/`](posts) — the blog's posts
- [`docs/`](docs) — design notes and sketches; [where things go, and why](docs/ja/layout.md), for every implementation
- [`TODO.md`](TODO.md) — open tasks ([archive](TODO-archive.md))
