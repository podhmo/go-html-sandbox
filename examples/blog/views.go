package main

import (
	"cmp"
	"net/http"
	"strconv"

	pe "github.com/podhmo/go-html-sandbox/pkg/picoel"
	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

const (
	siteName        = "blog"
	siteDescription = "Notes rendered with the Go standard library only."
)

// pageMeta describes a page for <head>.
type pageMeta struct {
	Title       string // page title without the site name; empty for the top page
	Description string
	// URL is the absolute URL of the page. OGP tags are written only when
	// it is set, so error pages have none.
	URL  string
	Type string // OGP type: "website" or "article"
}

// layout is the frame shared by every page. The doctype is written by render.
func layout(meta pageMeta, body ...pe.Node) pe.Node {
	head := []pe.Node{
		pe.Title(documentTitle(meta.Title)),
		pe.MetaName("description", meta.Description),
	}
	head = append(head, ogp(meta)...)
	head = append(head, pe.Icon("/favicon.svg", "image/svg+xml"))
	return pe.Document("en", head,
		pe.Header(pe.Nav(
			pe.A("/", pe.Strong(pe.Text(siteName))),
			pe.A("/docs/", pe.Text("docs")),
		)),
		pe.Main(body...),
		pe.Footer(pe.Small(pe.Text("Rendered with the Go standard library."))),
	)
}

// documentTitle is the <title> text: the page title followed by the site name.
func documentTitle(title string) string {
	if title == "" {
		return siteName
	}
	return title + " - " + siteName
}

// ogp returns Open Graph <meta> tags, or none when meta has no URL.
func ogp(meta pageMeta) []pe.Node {
	if meta.URL == "" {
		return nil
	}
	prop := pe.MetaProperty
	return []pe.Node{
		prop("og:title", cmp.Or(meta.Title, siteName)),
		prop("og:type", meta.Type),
		prop("og:url", meta.URL),
		prop("og:description", meta.Description),
		prop("og:site_name", siteName),
	}
}

// postList shows each post as a card: the title links to the post and the
// date below it is muted by hgroup.
func postList(baseURL string, posts []Post) pe.Node {
	body := []pe.Node{pe.H1(pe.Text("Posts"))}
	for _, p := range posts {
		body = append(body, pe.Article(pe.Hgroup(
			pe.H2(pe.A(postPath(p), pe.Text(p.Title))),
			pe.P(pe.Date(p.Date)),
		)))
	}
	return layout(pageMeta{Description: siteDescription, URL: baseURL + "/", Type: "website"}, body...)
}

func postPage(baseURL string, p Post) pe.Node {
	body := []pe.Node{pe.ArticleHeader(pe.Date(p.Date))}
	if _, ok := firstTitle(p.Doc); !ok {
		// The title came from front matter only, so the body has no heading.
		body = append(body, pe.H1(pe.Text(p.Title)))
	}
	body = append(body, renderBlocks(p.Doc.Children)...)
	meta := pageMeta{
		Title:       p.Title,
		Description: p.Description,
		URL:         baseURL + postPath(p),
		Type:        "article",
	}
	return layout(meta, pe.Article(body...))
}

// docList links to every repository document, showing its file path below
// the title.
func docList(baseURL string, docs []Doc) pe.Node {
	body := []pe.Node{pe.H1(pe.Text("Docs"))}
	for _, d := range docs {
		body = append(body, pe.Article(pe.Hgroup(
			pe.H2(pe.A(docPath(d), pe.Text(d.Title))),
			pe.P(pe.Text(d.Source)),
		)))
	}
	meta := pageMeta{Title: "Docs", Description: "Documents of this repository.", URL: baseURL + "/docs/", Type: "website"}
	return layout(meta, body...)
}

func docPage(baseURL string, d Doc) pe.Node {
	body := []pe.Node{pe.ArticleHeader(pe.Small(pe.Text(d.Source)))}
	if _, ok := firstTitle(d.Doc); !ok {
		body = append(body, pe.H1(pe.Text(d.Title)))
	}
	body = append(body, renderBlocks(d.Doc.Children)...)
	meta := pageMeta{Title: d.Title, Description: d.Description, URL: baseURL + docPath(d), Type: "article"}
	return layout(meta, pe.Article(body...))
}

func postPath(p Post) string {
	return "/posts/" + p.Slug
}

func errorPage(status int, message string) pe.Node {
	title := strconv.Itoa(status) + " " + http.StatusText(status)
	return layout(pageMeta{Title: title, Description: message},
		pe.H1(pe.Text(title)),
		pe.P(pe.Text(message)),
		pe.P(pe.A("/", pe.Text("Back to all posts"))),
	)
}

var headings = [...]func(...pe.Node) pe.Node{1: pe.H1, 2: pe.H2, 3: pe.H3}

// renderBlocks converts the Markdown tree into nodes. Every piece of text
// goes through pe.Text, so HTML in posts is escaped.
func renderBlocks(bs []tinymarkdown.Block) []pe.Node {
	out := make([]pe.Node, 0, len(bs))
	for _, b := range bs {
		switch b := b.(type) {
		case tinymarkdown.Section:
			children := append([]pe.Node{headings[b.Level](renderInlines(b.Title)...)}, renderBlocks(b.Children)...)
			out = append(out, pe.Section(children...))
		case tinymarkdown.Paragraph:
			out = append(out, pe.P(renderInlines(b.Text)...))
		case tinymarkdown.List:
			items := make([]pe.Node, 0, len(b.Items))
			for _, it := range b.Items {
				items = append(items, pe.Li(renderInlines(it)...))
			}
			out = append(out, pe.List(items...))
		case tinymarkdown.Quote:
			out = append(out, pe.Blockquote(renderBlocks(b.Children)...))
		case tinymarkdown.CodeBlock:
			out = append(out, pe.Pre(b.Code))
		}
	}
	return out
}

// renderInlines turns `code` spans in s into <code>; the rest is text.
func renderInlines(s string) []pe.Node {
	var out []pe.Node
	for _, in := range tinymarkdown.Inlines(s) {
		switch in := in.(type) {
		case tinymarkdown.Text:
			out = append(out, pe.Text(string(in)))
		case tinymarkdown.Code:
			out = append(out, pe.Code(string(in)))
		}
	}
	return out
}
