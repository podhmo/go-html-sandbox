package site

import (
	"cmp"
	"net/http"
	"path"
	"strconv"
	"strings"

	pe "github.com/podhmo/html-sandbox/go/pkg/picoel"
	"github.com/podhmo/html-sandbox/go/pkg/tinymarkdown"
)

const (
	siteName        = "blog"
	siteDescription = "Notes rendered with Wasm."
)

// pageMeta describes a page for <head>. Title and Description may hold
// inline Markdown, which layout reduces to plain text.
type pageMeta struct {
	Title       string // page title without the site name; empty for the top page
	Description string
	// URL is the absolute URL of the page. OGP tags are written only when
	// it is set, so error pages have none.
	URL  string
	Type string // OGP type: "website" or "article"
}

// pageEnv is what every page needs to know about the running server.
type pageEnv struct {
	BaseURL string // absolute, without a trailing slash
	// LiveReload loads the script that reloads the page when the server
	// says files have changed (the -watch flag).
	LiveReload bool
}

// layout is the frame shared by every page. The doctype is written by render.
func layout(env pageEnv, meta pageMeta, body ...pe.Node) pe.Node {
	meta.Title = plainText(meta.Title)
	meta.Description = plainText(meta.Description)
	head := []pe.Node{
		pe.Title(documentTitle(meta.Title)),
		pe.MetaName("description", meta.Description),
	}
	head = append(head, ogp(meta)...)
	head = append(head, pe.Stylesheet(siteCSSPath), pe.Icon("/favicon.svg", "image/svg+xml"))
	if env.LiveReload {
		head = append(head, pe.Script(liveReloadScriptPath))
	}
	return pe.Document("ja", head,
		pe.Header(pe.Nav(
			pe.A("/", pe.Strong(pe.Text(siteName))),
			pe.A("/docs/", pe.Text("docs")),
		)),
		pe.Main(body...),
		pe.Footer(pe.Small(pe.Text("Rendered with Wasm."))),
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
func postList(env pageEnv, posts []Post) pe.Node {
	body := []pe.Node{pe.H1(pe.Text("Posts"))}
	for _, p := range posts {
		body = append(body, pe.Article(pe.Hgroup(
			pe.H2(pe.A(postPath(p), linkedTitle(p.Title)...)),
			pe.P(pe.Date(p.Date)),
		)))
	}
	return layout(env, pageMeta{Description: siteDescription, URL: env.BaseURL + "/", Type: "website"}, body...)
}

func postPage(env pageEnv, link linker, p Post) pe.Node {
	var body []pe.Node
	if _, ok := firstTitle(p.Doc); !ok {
		// The title came from front matter only, so the body has no heading.
		body = append(body, pe.H1(renderInlines(tinymarkdown.Inlines(p.Title), link)...))
	}
	body = append(body, renderBlocks(p.Doc.Children, link)...)
	meta := pageMeta{
		Title:       p.Title,
		Description: p.Description,
		URL:         env.BaseURL + postPath(p),
		Type:        "article",
	}
	return layout(env, meta, pageHeader(pe.Date(p.Date), postMarkdownPath(p), p.File), pe.Article(body...))
}

// docList links to every repository document, showing its file path below
// the title.
func docList(env pageEnv, docs []Doc) pe.Node {
	body := []pe.Node{pe.H1(pe.Text("Docs"))}
	for _, d := range docs {
		body = append(body, pe.Article(pe.Hgroup(
			pe.H2(pe.A(docPath(d), linkedTitle(d.Title)...)),
			pe.P(pe.Text(d.Source)),
		)))
	}
	meta := pageMeta{Title: "Docs", Description: "Documents of this repository.", URL: env.BaseURL + "/docs/", Type: "website"}
	return layout(env, meta, body...)
}

func docPage(env pageEnv, link linker, d Doc) pe.Node {
	var body []pe.Node
	if _, ok := firstTitle(d.Doc); !ok {
		body = append(body, pe.H1(renderInlines(tinymarkdown.Inlines(d.Title), link)...))
	}
	body = append(body, renderBlocks(d.Doc.Children, link)...)
	meta := pageMeta{Title: d.Title, Description: d.Description, URL: env.BaseURL + docPath(d), Type: "article"}
	return layout(env, meta, pageHeader(pe.Small(pe.Text(d.Source)), docMarkdownPath(d), path.Base(d.Source)), pe.Article(body...))
}

func postPath(p Post) string {
	return "/posts/" + p.Slug
}

// postMarkdownPath is where the source of p is served.
func postMarkdownPath(p Post) string {
	return postPath(p) + ".md"
}

// pageHeader is the row above the article: info on the left and, on the
// right, a small link that downloads the page's Markdown source. It sits in
// main rather than in the article, where pico would pad it into a band.
func pageHeader(info pe.Node, href, filename string) pe.Node {
	download := pe.Small(pe.DownloadLink(href, filename, pe.Text("Download .md")))
	return pe.InnerHeader(pe.Spread([]pe.Node{info}, []pe.Node{download}))
}

func errorPage(env pageEnv, status int, message string) pe.Node {
	title := strconv.Itoa(status) + " " + http.StatusText(status)
	return layout(env, pageMeta{Title: title, Description: message},
		pe.H1(pe.Text(title)),
		pe.P(pe.Text(message)),
		pe.P(pe.A("/", pe.Text("Back to all posts"))),
	)
}

var headings = [...]func(...pe.Node) pe.Node{1: pe.H1, 2: pe.H2, 3: pe.H3, 4: pe.H4, 5: pe.H5}

// renderBlocks converts the Markdown tree into nodes. Every piece of text
// goes through pe.Text, so HTML in posts is escaped. link resolves the URLs
// of links.
func renderBlocks(bs []tinymarkdown.Block, link linker) []pe.Node {
	out := make([]pe.Node, 0, len(bs))
	for _, b := range bs {
		switch b := b.(type) {
		case tinymarkdown.Section:
			children := append([]pe.Node{headings[b.Level](renderInlines(tinymarkdown.Inlines(b.Title), link)...)}, renderBlocks(b.Children, link)...)
			out = append(out, pe.Section(children...))
		case tinymarkdown.Paragraph:
			out = append(out, pe.P(renderInlines(tinymarkdown.Inlines(b.Text), link)...))
		case tinymarkdown.List:
			out = append(out, renderList(b.Items, link))
		case tinymarkdown.Quote:
			out = append(out, pe.Blockquote(renderBlocks(b.Children, link)...))
		case tinymarkdown.Table:
			cells := func(row []string) [][]pe.Node {
				out := make([][]pe.Node, 0, len(row))
				for _, c := range row {
					out = append(out, renderInlines(tinymarkdown.Inlines(c), link))
				}
				return out
			}
			rows := make([][][]pe.Node, 0, len(b.Rows))
			for _, r := range b.Rows {
				rows = append(rows, cells(r))
			}
			out = append(out, pe.Table(cells(b.Header), rows))
		case tinymarkdown.CodeBlock:
			out = append(out, pe.Pre(b.Code))
		}
	}
	return out
}

// renderList renders items as a list, with the children of an item as a
// list inside its <li>.
func renderList(items []tinymarkdown.Item, link linker) pe.Node {
	lis := make([]pe.Node, 0, len(items))
	for _, it := range items {
		li := renderInlines(tinymarkdown.Inlines(it.Text), link)
		if len(it.Children) > 0 {
			li = append(li, renderList(it.Children, link))
		}
		lis = append(lis, pe.Li(li...))
	}
	return pe.List(lis...)
}

// linkedTitle renders a title written in Markdown inside the link to its
// page. Links in the title show only their text, as links cannot nest.
func linkedTitle(title string) []pe.Node {
	return renderInlines(tinymarkdown.Inlines(title), func(string) (string, bool) { return "", false })
}

// plainText drops the markup of inline Markdown: code spans and links keep
// only their text. It is for places that hold no HTML, such as <title>.
func plainText(s string) string {
	var b strings.Builder
	var walk func([]tinymarkdown.Inline)
	walk = func(ins []tinymarkdown.Inline) {
		for _, in := range ins {
			switch in := in.(type) {
			case tinymarkdown.Text:
				b.WriteString(string(in))
			case tinymarkdown.Code:
				b.WriteString(string(in))
			case tinymarkdown.Link:
				walk(in.Children)
			}
		}
	}
	walk(tinymarkdown.Inlines(s))
	return b.String()
}

// renderInlines turns code spans into <code> and links into <a>; the rest
// is text. A link whose URL link rejects shows only its text.
func renderInlines(ins []tinymarkdown.Inline, link linker) []pe.Node {
	var out []pe.Node
	for _, in := range ins {
		switch in := in.(type) {
		case tinymarkdown.Text:
			out = append(out, pe.Text(string(in)))
		case tinymarkdown.Code:
			out = append(out, pe.Code(string(in)))
		case tinymarkdown.Link:
			children := renderInlines(in.Children, link)
			if href, ok := link(in.URL); ok {
				out = append(out, pe.A(href, children...))
			} else {
				out = append(out, children...)
			}
		}
	}
	return out
}
