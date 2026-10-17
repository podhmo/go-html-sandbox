package el

import (
	"fmt"
	"io"
)

// Renderer writes nodes in some output format. Render dispatches each node
// to the matching method; ElementNode implementations call Render again for
// their children.
type Renderer interface {
	Text(w io.Writer, n TextNode) error
	Raw(w io.Writer, n RawNode) error
	Element(w io.Writer, n ElementNode) error
	Attr(w io.Writer, n AttrNode) error
	BoolAttr(w io.Writer, n BoolAttrNode) error
}

// Render writes n to w using r. This is the only place that switches on
// node types.
func Render(w io.Writer, n Node, r Renderer) error {
	switch n := n.(type) {
	case TextNode:
		return r.Text(w, n)
	case RawNode:
		return r.Raw(w, n)
	case ElementNode:
		return r.Element(w, n)
	case AttrNode:
		return r.Attr(w, n)
	case BoolAttrNode:
		return r.BoolAttr(w, n)
	case nil:
		return nil
	default:
		return fmt.Errorf("el: unknown node type %T", n)
	}
}

// isAttr reports whether n belongs in a start tag rather than in content.
func isAttr(n Node) bool {
	switch n.(type) {
	case AttrNode, BoolAttrNode:
		return true
	}
	return false
}

// voidElements have no content and no end tag.
var voidElements = map[Tag]bool{
	"area": true, "base": true, "br": true, "col": true, "embed": true,
	"hr": true, "img": true, "input": true, "link": true, "meta": true,
	"source": true, "track": true, "wbr": true,
}

// HTMLRenderer writes HTML5. The zero value is ready to use.
type HTMLRenderer struct{}

func (HTMLRenderer) Text(w io.Writer, n TextNode) error {
	return writeEscaped(w, string(n))
}

func (HTMLRenderer) Raw(w io.Writer, n RawNode) error {
	_, err := io.WriteString(w, string(n))
	return err
}

func (r HTMLRenderer) Element(w io.Writer, n ElementNode) error {
	// The tag is written in pieces rather than concatenated: io.WriteString
	// avoids the allocation that "<"+name+">" would make for every element.
	if _, err := io.WriteString(w, "<"); err != nil {
		return err
	}
	if _, err := io.WriteString(w, string(n.Name)); err != nil {
		return err
	}
	for _, c := range n.Children {
		if isAttr(c) {
			if err := Render(w, c, r); err != nil {
				return err
			}
		}
	}
	if _, err := io.WriteString(w, ">"); err != nil {
		return err
	}
	if voidElements[n.Name] {
		return nil
	}
	for _, c := range n.Children {
		if !isAttr(c) {
			if err := Render(w, c, r); err != nil {
				return err
			}
		}
	}
	if _, err := io.WriteString(w, "</"); err != nil {
		return err
	}
	if _, err := io.WriteString(w, string(n.Name)); err != nil {
		return err
	}
	_, err := io.WriteString(w, ">")
	return err
}

func (HTMLRenderer) Attr(w io.Writer, n AttrNode) error {
	if _, err := io.WriteString(w, " "); err != nil {
		return err
	}
	if _, err := io.WriteString(w, string(n.Name)); err != nil {
		return err
	}
	if _, err := io.WriteString(w, `="`); err != nil {
		return err
	}
	if err := writeEscaped(w, n.Value); err != nil {
		return err
	}
	_, err := io.WriteString(w, `"`)
	return err
}

// writeEscaped writes s to w with the characters html.EscapeString escapes,
// using the same replacements, but straight to w: no buffer and no string
// is built for every value that needs escaping.
func writeEscaped(w io.Writer, s string) error {
	last := 0
	for i := 0; i < len(s); i++ {
		var repl string
		switch s[i] {
		case '&':
			repl = "&amp;"
		case '\'':
			repl = "&#39;"
		case '<':
			repl = "&lt;"
		case '>':
			repl = "&gt;"
		case '"':
			repl = "&#34;"
		default:
			continue
		}
		if _, err := io.WriteString(w, s[last:i]); err != nil {
			return err
		}
		if _, err := io.WriteString(w, repl); err != nil {
			return err
		}
		last = i + 1
	}
	if _, err := io.WriteString(w, s[last:]); err != nil {
		return err
	}
	return nil
}

func (HTMLRenderer) BoolAttr(w io.Writer, n BoolAttrNode) error {
	_, err := io.WriteString(w, " "+string(n))
	return err
}

// PlainRenderer writes only text content, dropping tags, attributes, and raw
// markup. Text is not escaped. Block-level elements (paragraphs, headings,
// list items, ...) start and end on their own line, so the output reads like
// the page. Useful for debugging and for tests that check what a page says.
// The zero value is ready to use.
type PlainRenderer struct{}

func (PlainRenderer) Text(w io.Writer, n TextNode) error {
	_, err := io.WriteString(w, string(n))
	return err
}

func (PlainRenderer) Raw(io.Writer, RawNode) error { return nil }

func (r PlainRenderer) Element(w io.Writer, n ElementNode) error {
	lw, ok := w.(*lineWriter)
	if !ok {
		lw = &lineWriter{w: w}
	}
	block := blockElements[n.Name]
	if block {
		if err := lw.breakLine(); err != nil {
			return err
		}
	}
	for _, c := range n.Children {
		if err := Render(lw, c, r); err != nil {
			return err
		}
	}
	if block {
		return lw.breakLine()
	}
	return nil
}

func (PlainRenderer) Attr(io.Writer, AttrNode) error { return nil }

func (PlainRenderer) BoolAttr(io.Writer, BoolAttrNode) error { return nil }

// blockElements are put on their own lines by PlainRenderer.
var blockElements = map[Tag]bool{
	"address": true, "article": true, "aside": true, "blockquote": true,
	"body": true, "br": true, "dd": true, "details": true, "div": true,
	"dl": true, "dt": true, "figcaption": true, "figure": true,
	"footer": true, "form": true, "h1": true, "h2": true, "h3": true,
	"h4": true, "h5": true, "h6": true, "head": true, "header": true, "hgroup": true,
	"hr": true, "html": true, "li": true, "main": true, "nav": true,
	"ol": true, "p": true, "pre": true, "section": true, "summary": true,
	"table": true, "title": true, "tr": true, "ul": true,
}

// lineWriter remembers the last byte written so that breakLine never emits
// a blank line or a leading newline.
type lineWriter struct {
	w    io.Writer
	last byte // 0 until something is written
}

func (lw *lineWriter) Write(p []byte) (int, error) {
	n, err := lw.w.Write(p)
	if n > 0 {
		lw.last = p[n-1]
	}
	return n, err
}

func (lw *lineWriter) breakLine() error {
	if lw.last == 0 || lw.last == '\n' {
		return nil
	}
	_, err := lw.Write([]byte{'\n'})
	return err
}
