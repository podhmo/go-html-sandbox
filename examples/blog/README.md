# blog

A mobile-first, server-side rendered blog built on `pkg/picoel`,
`pkg/tinymarkdown`, and `pkg/tinyfrontmatter`. It uses only the Go standard
library: there is no template engine, no JavaScript (except the `-watch`
reload script), and no CSS of its own.
Styling is [pico.css v2](https://picocss.com/docs) alone, loaded from a CDN;
pages are made of semantic elements and pico's `container` class.
Posts, the favicon, and the repository's own documents are embedded with
`go:embed`, so the binary is all you need to run it.

See the [sketch](../../docs/sketch/ja/blog.md) for the design.

## Running

From the repository root:

```sh
go run ./examples/blog
```

Then open <http://localhost:8080>.

| Flag | Default | Description |
| --- | --- | --- |
| `-addr` | `localhost:8080` | Address to listen on. |
| `-base-url` | `http://<addr>` | Public origin used for absolute URLs in OGP tags, e.g. `https://example.com`. Must not contain a path. |
| `-debug` | off | Read posts and docs from files under `-root` instead of the embedded copies. |
| `-watch` | off | Reload posts and docs when they change and refresh open pages. Implies `-debug`. |
| `-root` | nearest `go.mod` above the current directory | Module root that `-debug` reads from. It must hold `go.mod`; nothing outside it is read, even through symbolic links. |

To build a single binary:

```sh
go build -o blog ./examples/blog
./blog -addr :8080 -base-url https://example.com
```

Posts are embedded at build time, so rebuild after editing them. While
writing, run with `-watch` instead:

```sh
go run ./examples/blog -watch
```

It reads `examples/blog/posts/`, `TODO.md`, and `docs/` from disk, checks
their sizes and modification times every 0.5 seconds, and on a change
reloads them and tells open pages to reload over server-sent events
(`/_livereload`). If a changed post has an error, the error is logged and
the previous content stays. Pages load the small reload script
(`/_livereload.js`) only in this mode.

## Markdown source

Every post and document can also be fetched as the Markdown it was written
in: add `.md` to its URL, e.g. `/posts/hello.md` or `/docs/TODO.md`. It is
served as `text/markdown; charset=utf-8`, and each page links to it with a small
"Download .md" link at the top right of the article.

## Cloudflare Workers (experimental)

[`workers/`](workers/) is a separate Go module that serves the same site on
Cloudflare Workers through
[syumai/workers-go](https://github.com/syumai/workers-go), so only that
module depends on workers-go. It has no flags; the public origin for OGP
tags comes from `BASE_URL` in [`workers/wrangler.jsonc`](workers/wrangler.jsonc).

```sh
cd examples/blog/workers
npx wrangler dev   # needs TinyGo 0.42.0 or later on PATH
```

The site itself lives in `internal/site`, which is tested under TinyGo too:

```sh
tinygo test ./examples/blog/internal/site
```

See the [experiment report](../../docs/sketch/ja/blog-tinygo-workers.md).

## Pages

| Path | Page |
| --- | --- |
| `/` | Post list, newest first |
| `/posts/{slug}` | A post |
| `/docs/` | Repository documents: `TODO.md` and `docs/**/*.md` |
| `/docs/{path}` | A document; `TODO.md` is `/docs/TODO`, `docs/ja/design.md` is `/docs/ja/design` |
| `/favicon.svg` | The embedded favicon |
| anything else | 404 error page |

## Writing posts

Add a file to [`posts/`](posts/) named `YYYY-MM-DD-slug.md`. The date and
slug come from the file name; the slug may contain `a-z`, `0-9`, and `-`.

A post may start with front matter. Only `title` and `description` are
allowed:

```markdown
---
title: Hello
description: Shown in <meta name="description"> and OGP.
---
```

Each key falls back on its own: without `title`, the title is the first
top-level `#` heading (a post with neither is an error at startup); without
`description`, the description is the first paragraph. When the title comes
from front matter and the body has no `#` heading, the post page adds one.

The body supports a tiny subset of Markdown:

- `#` to `###` headings, which open nested sections
- `- ` list items (no nesting); indented lines continue the item above
- paragraphs
- `>` quotes, whose content is Markdown again
- `` `code` `` spans in headings, paragraphs, and list items
- code blocks fenced by exactly three backquotes (no highlighting)

Everything else, including other inline syntax and HTML, is shown as plain,
escaped text. Problems such as a bad file name, a duplicate slug, a missing
title, or an unknown front matter key stop the server at startup.

## Files

| File | Contents |
| --- | --- |
| `main.go` | Flags and startup |
| `repo.go` | Finding and opening the module root for `-debug` |
| `posts/embed.go` | Embedding the posts |
| `internal/site/content.go` | Embedded favicon, posts, and documents |
| `internal/site/posts.go` | Loading posts from an `fs.FS` |
| `internal/site/docs.go` | Loading repository documents (embedded by the root package, [`embed.go`](../../embed.go)) |
| `internal/site/livereload.go` | `-watch`: polling, reloading, and the SSE endpoint |
| `internal/site/server.go` | Routing (by hand, see `route`), rendering, error pages, panic recovery |
| `internal/site/views.go` | Pages built from `pkg/picoel`, OGP tags |
| `workers/` | Cloudflare Workers entry point (a module of its own) |

## Testing

```sh
go test ./examples/blog/...
```

Tests load posts from a `fstest.MapFS` and exercise the handlers with
`httptest`.
