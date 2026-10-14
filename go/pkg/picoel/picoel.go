// Package picoel builds pages styled by pico.css v2, on top of pkg/el.
//
// It provides only the elements the blog needs. Following pico's approach,
// there are no custom classes: layout and decoration come from semantic
// elements (article, nav, hgroup, ...) and the classes pico ships with
// (container). The few rules pico cannot express, such as a sticky header,
// go in a small stylesheet linked with Stylesheet. Every helper returns an el.Node, so the result is plain
// data rendered by an el.Renderer like any other tree.
package picoel

import (
	"io"
	"time"

	"github.com/podhmo/html-sandbox/go/pkg/el"
)

// Aliases so that callers can render pages without importing pkg/el.
type (
	Node          = el.Node
	Renderer      = el.Renderer
	HTMLRenderer  = el.HTMLRenderer
	PlainRenderer = el.PlainRenderer
)

// Render writes n to w using r.
func Render(w io.Writer, n Node, r Renderer) error {
	return el.Render(w, n, r)
}

// StylesheetURL is pico.css v2 on a CDN.
const StylesheetURL = "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"

// Document is the <html> element in pico's dark theme: the head carries the
// charset, viewport, color scheme, and the pico stylesheet, followed by head.
// The doctype is the caller's job.
func Document(lang string, head []Node, body ...Node) Node {
	h := []Node{
		el.El(el.Meta, el.Attr(el.Charset, "utf-8")),
		MetaName("viewport", "width=device-width, initial-scale=1"),
		MetaName("color-scheme", "dark"),
		Stylesheet(StylesheetURL),
	}
	return el.El(el.HTML, el.Attr(el.Lang, lang), el.Attr(el.AttrName("data-theme"), "dark"),
		el.El(el.Head, append(h, head...)...),
		el.El(el.Body, body...),
	)
}

// Title is the document title.
func Title(s string) Node {
	return el.El(el.Title, el.Text(s))
}

// MetaName is <meta name content>.
func MetaName(name, content string) Node {
	return el.El(el.Meta, el.Attr(el.Name, name), el.Attr(el.Content, content))
}

// MetaProperty is <meta property content>, as used by Open Graph.
func MetaProperty(property, content string) Node {
	return el.El(el.Meta, el.Attr(el.Property, property), el.Attr(el.Content, content))
}

// Stylesheet links the stylesheet at href. Document already links pico;
// use this for the few rules pico cannot express, placed after it.
func Stylesheet(href string) Node {
	return el.El(el.Link, el.Attr(el.Rel, "stylesheet"), el.Attr(el.Href, href))
}

// Icon links the favicon at href with the given MIME type.
func Icon(href, mimeType string) Node {
	return el.El(el.Link, el.Attr(el.Rel, "icon"), el.Attr(el.Href, href), el.Attr(el.Type, mimeType))
}

// Script loads the external script at src after the document is parsed.
// pico itself needs no JavaScript; use this only for development aids.
func Script(src string) Node {
	return el.El(el.Script, el.Attr(el.Src, src), el.BoolAttrNode(el.Defer))
}

// container is pico's centered, responsive width.
var container = el.Attr(el.Class, "container")

// Header is the page header, centered by .container.
func Header(children ...Node) Node {
	return el.El(el.Header, append([]Node{container}, children...)...)
}

// Main is the page body, centered by .container.
func Main(children ...Node) Node {
	return el.El(el.Main, append([]Node{container}, children...)...)
}

// Footer is the page footer, centered by .container.
func Footer(children ...Node) Node {
	return el.El(el.Footer, append([]Node{container}, children...)...)
}

// Nav is a navigation bar. Each item becomes a list item; pico lays them
// out in a row.
func Nav(items ...Node) Node {
	return el.El(el.Nav, el.El(el.Ul, listItems(items)...))
}

// Spread puts start at the leading edge and end at the trailing edge of one
// row, using pico's nav layout: each side is a list and the lists are pushed
// apart.
func Spread(start, end []Node) Node {
	return el.El(el.Nav, el.El(el.Ul, listItems(start)...), el.El(el.Ul, listItems(end)...))
}

// Article is a card.
func Article(children ...Node) Node {
	return el.El(el.Article, children...)
}

// InnerHeader is a header without .container, for use inside Main or an
// Article rather than at the top of the page. Inside an Article pico draws
// it as a band.
func InnerHeader(children ...Node) Node {
	return el.El(el.Header, children...)
}

// Hgroup groups a heading with lines that pico shows in a muted color.
func Hgroup(children ...Node) Node {
	return el.El(el.Hgroup, children...)
}

// Section is a section of a document.
func Section(children ...Node) Node {
	return el.El(el.Section, children...)
}

// H1 is a level 1 heading.
func H1(children ...Node) Node { return el.El(el.H1, children...) }

// H2 is a level 2 heading.
func H2(children ...Node) Node { return el.El(el.H2, children...) }

// H3 is a level 3 heading.
func H3(children ...Node) Node { return el.El(el.H3, children...) }

// H4 is a level 4 heading.
func H4(children ...Node) Node { return el.El(el.H4, children...) }

// H5 is a level 5 heading.
func H5(children ...Node) Node { return el.El(el.H5, children...) }

// P is a paragraph.
func P(children ...Node) Node {
	return el.El(el.P, children...)
}

// List is an unordered list of Li items.
func List(items ...Node) Node {
	return el.El(el.Ul, items...)
}

// Li is a list item.
func Li(children ...Node) Node {
	return el.El(el.Li, children...)
}

// Blockquote is a quotation; pico draws a bar on its leading edge.
func Blockquote(children ...Node) Node {
	return el.El(el.Blockquote, children...)
}

// Table is a table with a header row and body rows; each cell is a list of
// nodes. It is wrapped in pico's overflow-auto div so that a wide table
// scrolls sideways instead of widening the page on small screens.
func Table(header [][]Node, rows [][][]Node) Node {
	row := func(tag el.Tag, cells [][]Node) Node {
		tr := make([]Node, 0, len(cells))
		for _, c := range cells {
			tr = append(tr, el.El(tag, c...))
		}
		return el.El(el.Tr, tr...)
	}
	parts := []Node{el.El(el.Thead, row(el.Th, header))}
	if len(rows) > 0 {
		body := make([]Node, 0, len(rows))
		for _, r := range rows {
			body = append(body, row(el.Td, r))
		}
		parts = append(parts, el.El(el.Tbody, body...))
	}
	return el.El(el.Div, el.Attr(el.Class, "overflow-auto"), el.El(el.Table, parts...))
}

// Pre is preformatted text such as a code block.
func Pre(text string) Node {
	return el.El(el.Pre, el.Text(text))
}

// Code is a fragment of code inside text.
func Code(text string) Node {
	return el.El(el.Code, el.Text(text))
}

// A is a link to href.
func A(href string, children ...Node) Node {
	return el.El(el.A, append([]Node{el.Attr(el.Href, href)}, children...)...)
}

// DownloadLink is a link that downloads href as filename, in pico's muted
// secondary color.
func DownloadLink(href, filename string, children ...Node) Node {
	attrs := []Node{
		el.Attr(el.Href, href),
		el.Attr(el.Download, filename),
		el.Attr(el.Class, "secondary"),
	}
	return el.El(el.A, append(attrs, children...)...)
}

// Strong is strong importance, e.g. the site name in a Nav.
func Strong(children ...Node) Node {
	return el.El(el.Strong, children...)
}

// Small is side comments and fine print.
func Small(children ...Node) Node {
	return el.El(el.Small, children...)
}

// Date is a <time> showing d as YYYY-MM-DD.
func Date(d time.Time) Node {
	s := d.Format(time.DateOnly)
	return el.El(el.Time, el.Attr(el.DateTime, s), el.Text(s))
}

// Text is escaped text.
func Text(s string) Node {
	return el.Text(s)
}

func listItems(items []Node) []Node {
	lis := make([]Node, 0, len(items))
	for _, it := range items {
		lis = append(lis, el.El(el.Li, it))
	}
	return lis
}
