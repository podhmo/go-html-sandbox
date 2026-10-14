# blog

A mobile-first, server-side rendered blog built on `pkg/picoel`,
`pkg/tinymarkdown`, and `pkg/tinyfrontmatter`. It uses only the Go standard
library: there is no template engine, no JavaScript (except the `-watch`
reload script), and no CSS classes of its own.
Styling is [pico.css v2](https://picocss.com/docs), loaded from a CDN;
pages are made of semantic elements and pico's `container` class.
The few rules pico cannot express (a sticky site header and tighter spacing
around `header` and `main`) and typography tuned for Japanese (leading,
heading sizes and wrapping, list indent and leading, list cards) live in
[`internal/site/site.css`](internal/site/site.css), which builds on pico's
variables and is served as `/site.css?v=<hash>` after pico.
Pages are written with `lang="ja"`, since the posts are in Japanese.
Posts, the favicon, and the repository's own documents are embedded with
`go:embed`, so the binary is all you need to run it. The documents
(`TODO.md` and `docs/`) sit above this module (`go/`), out of reach of
`go:embed`, so `go generate ./...` copies them into `repodocs/files/` first;
the copies are not committed. Without them the blog still builds, and
`/docs/` lists nothing.

See the [sketch](../../../docs/sketch/ja/blog.md) for the design.

## Running

From `go/`:

```sh
go generate ./...
go run ./examples/blog
```

Then open <http://localhost:8080>.

| Flag | Default | Description |
| --- | --- | --- |
| `-addr` | `localhost:8080` | Address to listen on. |
| `-base-url` | `http://<addr>` | Public origin used for absolute URLs in OGP tags, e.g. `https://example.com`. Must not contain a path. |
| `-debug` | off | Read posts from files under `-root`, and docs from its parent directory (the repository root), instead of the embedded copies. |
| `-watch` | off | Reload posts and docs when they change and refresh open pages. Implies `-debug`. |
| `-root` | nearest `go.mod` above the current directory | Module root that `-debug` reads posts from. It must hold `go.mod`. Nothing outside it, or outside its parent for docs, is read, even through symbolic links. |

To build a single binary:

```sh
go build -o blog ./examples/blog
./blog -addr :8080 -base-url https://example.com
```

Posts and docs are embedded at build time, so rebuild (and rerun
`go generate ./...` for docs) after editing them. While writing, run with
`-watch` instead:

```sh
go run ./examples/blog -watch
```

It reads `examples/blog/posts/`, and `TODO.md` and `docs/` in the
repository root, from disk, checks their sizes and modification times
every 0.5 seconds, and on a change
reloads them and tells open pages to reload over server-sent events
(`/_livereload`). If a changed post has an error, the error is logged and
the previous content stays. Pages load the small reload script
(`/_livereload.js`) only in this mode.

## Markdown source

Every post and document can also be fetched as the Markdown it was written
in: add `.md` to its URL, e.g. `/posts/hello.md` or `/docs/TODO.md`. It is
served as `text/markdown; charset=utf-8`, and each page links to it with a small
"Download .md" link at the top right, above the article.

## Cloudflare Workers (experimental)

[`workers/`](workers/) is a separate Go module that serves the same site on
Cloudflare Workers through
[syumai/workers-go](https://github.com/syumai/workers-go), built with
TinyGo (also through Docker) or the standard Go toolchain. See
[`workers/README.md`](workers/README.md) for running and deploying it.

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

- `#` to `#####` headings, which open nested sections
- `- ` list items (no nesting); indented lines continue the item above
- paragraphs
- `>` quotes, whose content is Markdown again
- tables of `|` rows with a `| --- |` delimiter row as the second line
  (no column alignment); wide tables scroll sideways
- `` `code` `` spans and `[text](url)` links in headings, paragraphs,
  list items, and table cells (see [Links](#links))
- code blocks fenced by exactly three backquotes (no highlighting)

Everything else, including other inline syntax and HTML, is shown as plain,
escaped text. Problems such as a bad file name, a duplicate slug, a missing
title, or an unknown front matter key stop the server at startup.

## Links

Relative link URLs are resolved against the file they are written in, as
on GitHub, so the same Markdown works in both places:

- a link to a document under `/docs/` (`TODO.md`, `docs/**/*.md`) or to a
  post goes to its page, e.g. `docs/ja/design.md` from `TODO.md` becomes
  `/docs/ja/design`; posts live at `go/examples/blog/posts/` in the repository
- a link to any other file in the repository goes to that file on GitHub
  (the `main` branch)
- a link that leaves the repository is not a link: only its text is shown

URLs starting with `/` or `#` are kept as written. URLs with a scheme are
linked only for `http`, `https`, and `mailto`; others, such as
`javascript:`, show only the text.

## Files

| File | Contents |
| --- | --- |
| `main.go` | Flags and startup |
| `repo.go` | Finding and opening the module root for `-debug` |
| `posts/embed.go` | Embedding the posts |
| `internal/site/content.go` | Embedded favicon, posts, and documents |
| `internal/site/posts.go` | Loading posts from an `fs.FS` |
| `internal/site/docs.go` | Loading repository documents |
| `repodocs/repodocs.go` | Embedding the repository documents, copied in by `go generate` |
| `internal/site/livereload.go` | `-watch`: polling, reloading, and the SSE endpoint |
| `internal/site/server.go` | Routing (by hand, see `route`), rendering, error pages, panic recovery |
| `internal/site/views.go` | Pages built from `pkg/picoel`, OGP tags |
| `internal/site/links.go` | Resolving the URLs of Markdown links |
| `workers/` | Cloudflare Workers entry point (a module of its own) |

## Testing

```sh
go test ./examples/blog/...
```

Tests load posts from a `fstest.MapFS` and exercise the handlers with
`httptest`.
