# blog

A mobile-first, server-side rendered blog built on `pkg/picoel`,
`pkg/tinymarkdown`, and `pkg/tinyfrontmatter`. It uses only the Go standard
library: there is no template engine, no JavaScript, and no CSS of its own.
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

To build a single binary:

```sh
go build -o blog ./examples/blog
./blog -addr :8080 -base-url https://example.com
```

Posts are embedded at build time, so rebuild after editing them.

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

Without front matter, the title is the first `#` heading and the
description is the first paragraph.

The body supports a tiny subset of Markdown:

- `#` to `###` headings, which open nested sections
- `- ` list items (no nesting); indented lines continue the item above
- paragraphs
- code blocks fenced by exactly three backquotes (no highlighting)

Everything else, including inline syntax and HTML, is shown as plain,
escaped text. Problems such as a bad file name, a duplicate slug, a missing
title, or an unknown front matter key stop the server at startup.

## Files

| File | Contents |
| --- | --- |
| `main.go` | Flags, embedding, startup |
| `posts.go` | Loading posts from an `fs.FS` |
| `docs.go` | Loading repository documents (embedded by the root package, [`embed.go`](../../embed.go)) |
| `server.go` | Routing, rendering, error pages, panic recovery |
| `views.go` | Pages built from `pkg/picoel`, OGP tags |

## Testing

```sh
go test ./examples/blog
```

Tests load posts from a `fstest.MapFS` and exercise the handlers with
`httptest`.
