package el

import (
	"fmt"
	"html"
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
	_, err := io.WriteString(w, html.EscapeString(string(n)))
	return err
}

func (HTMLRenderer) Raw(w io.Writer, n RawNode) error {
	_, err := io.WriteString(w, string(n))
	return err
}

func (r HTMLRenderer) Element(w io.Writer, n ElementNode) error {
	if _, err := io.WriteString(w, "<"+string(n.Name)); err != nil {
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
	_, err := io.WriteString(w, "</"+string(n.Name)+">")
	return err
}

func (HTMLRenderer) Attr(w io.Writer, n AttrNode) error {
	_, err := io.WriteString(w, " "+string(n.Name)+`="`+html.EscapeString(n.Value)+`"`)
	return err
}

func (HTMLRenderer) BoolAttr(w io.Writer, n BoolAttrNode) error {
	_, err := io.WriteString(w, " "+string(n))
	return err
}

// PlainRenderer writes only text content, dropping tags, attributes, and raw
// markup. Text is not escaped. Useful for debugging and for tests that check
// what a page says. The zero value is ready to use.
type PlainRenderer struct{}

func (PlainRenderer) Text(w io.Writer, n TextNode) error {
	_, err := io.WriteString(w, string(n))
	return err
}

func (PlainRenderer) Raw(io.Writer, RawNode) error { return nil }

func (r PlainRenderer) Element(w io.Writer, n ElementNode) error {
	for _, c := range n.Children {
		if err := Render(w, c, r); err != nil {
			return err
		}
	}
	return nil
}

func (PlainRenderer) Attr(io.Writer, AttrNode) error { return nil }

func (PlainRenderer) BoolAttr(io.Writer, BoolAttrNode) error { return nil }
