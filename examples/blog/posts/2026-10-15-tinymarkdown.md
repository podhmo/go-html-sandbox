# What tinymarkdown supports

Posts are written in a deliberately tiny subset of Markdown.
Anything outside it is shown as plain text, so <b>this</b> stays escaped.

## Sections

Headings from # to ### open nested sections.

### A third-level heading

Deeper headings are not supported and stay as paragraph text:

#### like this one

## Lists

- One item per line, starting with "- ".
- No nesting and no numbered lists.
- A blank line ends the list.

## Code blocks

Fences are exactly three backquotes. The language name is ignored and there is no highlighting.

```go
func Render(w io.Writer, n Node, r Renderer) error {
	switch n := n.(type) {
	case TextNode:
		return r.Text(w, n) // a long line to check that narrow screens scroll horizontally instead of wrapping
	}
	return nil
}
```

Text after the code block is a paragraph again.
