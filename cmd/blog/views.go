package main

import (
	"time"

	"github.com/podhmo/go-html-sandbox/pkg/el"
	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

const siteName = "blog"

// layout is the frame shared by every page. The doctype is written by render.
func layout(title string, body ...el.Node) el.Node {
	return el.El(el.HTML, el.Attr(el.Lang, "en"),
		el.El(el.Head,
			el.El(el.Meta, el.Attr(el.Charset, "utf-8")),
			el.El(el.Meta, el.Attr(el.Name, "viewport"), el.Attr(el.Content, "width=device-width, initial-scale=1")),
			el.El(el.Meta, el.Attr(el.Name, "color-scheme"), el.Attr(el.Content, "light dark")),
			el.El(el.Title, el.Text(title)),
			el.El(el.Link, el.Attr(el.Rel, "icon"), el.Attr(el.Href, "/favicon.svg"), el.Attr(el.Type, "image/svg+xml")),
			el.El(el.Style, el.Raw(css)),
		),
		el.El(el.Body,
			el.El(el.Header, el.El(el.A, el.Attr(el.Href, "/"), el.Attr(el.Class, "site"), el.Text(siteName))),
			el.El(el.Main, body...),
			el.El(el.Footer, el.Text("Rendered with the Go standard library.")),
		),
	)
}

func postList(posts []Post) el.Node {
	items := make([]el.Node, 0, len(posts))
	for _, p := range posts {
		items = append(items, el.El(el.Li,
			el.El(el.A, el.Attr(el.Href, "/posts/"+p.Slug),
				el.El(el.Span, el.Attr(el.Class, "title"), el.Text(p.Title)),
				dateNode(p.Date),
			),
		))
	}
	return layout(siteName,
		el.El(el.H1, el.Text("Posts")),
		el.El(el.Ul, append([]el.Node{el.Attr(el.Class, "posts")}, items...)...),
	)
}

func postPage(p Post) el.Node {
	body := append([]el.Node{dateNode(p.Date)}, renderBlocks(p.Doc.Children)...)
	return layout(p.Title+" - "+siteName, el.El(el.Article, body...))
}

func dateNode(d time.Time) el.Node {
	s := d.Format(time.DateOnly)
	return el.El(el.Time, el.Attr(el.DateTime, s), el.Text(s))
}

var headings = [...]el.Tag{1: el.H1, 2: el.H2, 3: el.H3}

// renderBlocks converts the Markdown tree into nodes. Every piece of text
// goes through el.Text, so HTML in posts is escaped.
func renderBlocks(bs []tinymarkdown.Block) []el.Node {
	out := make([]el.Node, 0, len(bs))
	for _, b := range bs {
		switch b := b.(type) {
		case tinymarkdown.Section:
			children := append([]el.Node{el.El(headings[b.Level], el.Text(b.Title))}, renderBlocks(b.Children)...)
			out = append(out, el.El(el.Section, children...))
		case tinymarkdown.Paragraph:
			out = append(out, el.El(el.P, el.Text(b.Text)))
		case tinymarkdown.List:
			items := make([]el.Node, 0, len(b.Items))
			for _, it := range b.Items {
				items = append(items, el.El(el.Li, el.Text(it)))
			}
			out = append(out, el.El(el.Ul, items...))
		case tinymarkdown.CodeBlock:
			out = append(out, el.El(el.Pre, el.Text(b.Code)))
		}
	}
	return out
}
