package main

import (
	"net/http"
	"strconv"
	"time"

	"github.com/podhmo/go-html-sandbox/pkg/el"
	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

const (
	siteName        = "blog"
	siteDescription = "Notes rendered with the Go standard library only."
)

// pageMeta describes a page for <head>.
type pageMeta struct {
	Title       string
	Description string
	// URL is the absolute URL of the page. OGP tags are written only when
	// it is set, so error pages have none.
	URL  string
	Type string // OGP type: "website" or "article"
}

// layout is the frame shared by every page. The doctype is written by render.
func layout(meta pageMeta, body ...el.Node) el.Node {
	head := []el.Node{
		el.El(el.Meta, el.Attr(el.Charset, "utf-8")),
		el.El(el.Meta, el.Attr(el.Name, "viewport"), el.Attr(el.Content, "width=device-width, initial-scale=1")),
		el.El(el.Meta, el.Attr(el.Name, "color-scheme"), el.Attr(el.Content, "light dark")),
		el.El(el.Title, el.Text(meta.Title)),
		el.El(el.Meta, el.Attr(el.Name, "description"), el.Attr(el.Content, meta.Description)),
	}
	head = append(head, ogp(meta)...)
	head = append(head,
		el.El(el.Link, el.Attr(el.Rel, "icon"), el.Attr(el.Href, "/favicon.svg"), el.Attr(el.Type, "image/svg+xml")),
		el.El(el.Style, el.Raw(css)),
	)
	return el.El(el.HTML, el.Attr(el.Lang, "en"),
		el.El(el.Head, head...),
		el.El(el.Body,
			el.El(el.Header, el.El(el.A, el.Attr(el.Href, "/"), el.Attr(el.Class, "site"), el.Text(siteName))),
			el.El(el.Main, body...),
			el.El(el.Footer, el.Text("Rendered with the Go standard library.")),
		),
	)
}

// ogp returns Open Graph <meta> tags, or none when meta has no URL.
func ogp(meta pageMeta) []el.Node {
	if meta.URL == "" {
		return nil
	}
	prop := func(property, content string) el.Node {
		return el.El(el.Meta, el.Attr(el.Property, property), el.Attr(el.Content, content))
	}
	return []el.Node{
		prop("og:title", meta.Title),
		prop("og:type", meta.Type),
		prop("og:url", meta.URL),
		prop("og:description", meta.Description),
		prop("og:site_name", siteName),
	}
}

func postList(baseURL string, posts []Post) el.Node {
	items := make([]el.Node, 0, len(posts))
	for _, p := range posts {
		items = append(items, el.El(el.Li,
			el.El(el.A, el.Attr(el.Href, postPath(p)),
				el.El(el.Span, el.Attr(el.Class, "title"), el.Text(p.Title)),
				dateNode(p.Date),
			),
		))
	}
	return layout(pageMeta{Title: siteName, Description: siteDescription, URL: baseURL + "/", Type: "website"},
		el.El(el.H1, el.Text("Posts")),
		el.El(el.Ul, append([]el.Node{el.Attr(el.Class, "posts")}, items...)...),
	)
}

func postPage(baseURL string, p Post) el.Node {
	body := []el.Node{dateNode(p.Date)}
	if _, ok := firstTitle(p.Doc); !ok {
		// The title came from front matter only, so the body has no heading.
		body = append(body, el.El(el.H1, el.Text(p.Title)))
	}
	body = append(body, renderBlocks(p.Doc.Children)...)
	meta := pageMeta{
		Title:       p.Title + " - " + siteName,
		Description: p.Description,
		URL:         baseURL + postPath(p),
		Type:        "article",
	}
	return layout(meta, el.El(el.Article, body...))
}

func postPath(p Post) string {
	return "/posts/" + p.Slug
}

func errorPage(status int, message string) el.Node {
	title := strconv.Itoa(status) + " " + http.StatusText(status)
	return layout(pageMeta{Title: title + " - " + siteName, Description: message},
		el.El(el.H1, el.Text(title)),
		el.El(el.P, el.Text(message)),
		el.El(el.P, el.El(el.A, el.Attr(el.Href, "/"), el.Text("Back to all posts"))),
	)
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
