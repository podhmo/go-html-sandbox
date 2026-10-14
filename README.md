# go-html-sandbox

Classic server-side rendered HTML with the Go standard library only.

- `pkg/el` — HTML as plain data, rendered by a `Renderer` ([design](docs/ja/design.md))
- `pkg/tinymarkdown` — a tiny Markdown parser (sections, lists, paragraphs, code blocks)
- `pkg/tinyfrontmatter` — splits a `---` block of `key: value` lines from a document
- `cmd/blog` — a mobile-first blog built on the above ([sketch](docs/sketch/ja/blog.md))

## Development

Run these before every commit:

```sh
gofmt -l .      # must print nothing; fix with gofmt -w .
go vet ./...
go test ./...
```
