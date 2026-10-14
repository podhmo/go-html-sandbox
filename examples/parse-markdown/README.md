# parse-markdown

Prints the tree that [`pkg/tinymarkdown`](../../pkg/tinymarkdown) builds
from Markdown, one block per line. Use it to check how a document is
understood before rendering it: anything tinymarkdown does not support
(numbered or nested lists, tables without a delimiter row, ...) shows up as paragraph
text.

```sh
go run ./examples/parse-markdown TODO.md docs/ja/design.md
cat post.md | go run ./examples/parse-markdown
```

With no arguments it reads stdin. With more than one file, each dump is
headed by `== path`.

```text
section h1 "Title"
  list
    item "a"
  section h2 "Sub"
    paragraph "| x | y |\n| - | - |"
    code "x := 1"
```

Text is quoted with Go's `%q`, so a `\n` inside a paragraph is a hint that
the source used a construct tinymarkdown left as plain text.
