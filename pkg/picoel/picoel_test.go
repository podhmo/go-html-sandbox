package picoel

import (
	"strings"
	"testing"
	"time"
)

func render(t *testing.T, n Node) string {
	t.Helper()
	var b strings.Builder
	if err := Render(&b, n, HTMLRenderer{}); err != nil {
		t.Fatal(err)
	}
	return b.String()
}

func TestDocument(t *testing.T) {
	got := render(t, Document("en", []Node{Title("T")}, Main(P(Text("x")))))
	want := `<html lang="en" data-theme="dark"><head>` +
		`<meta charset="utf-8">` +
		`<meta name="viewport" content="width=device-width, initial-scale=1">` +
		`<meta name="color-scheme" content="dark">` +
		`<link rel="stylesheet" href="` + StylesheetURL + `">` +
		`<title>T</title>` +
		`</head><body><main class="container"><p>x</p></main></body></html>`
	if got != want {
		t.Errorf("got\n%s\nwant\n%s", got, want)
	}
}

func TestElements(t *testing.T) {
	d := time.Date(2026, 10, 14, 9, 0, 0, 0, time.UTC)
	cases := []struct {
		n    Node
		want string
	}{
		{Header(Text("h")), `<header class="container">h</header>`},
		{Footer(Text("f")), `<footer class="container">f</footer>`},
		{InnerHeader(Text("h")), `<header>h</header>`},
		{Nav(A("/", Strong(Text("s")))), `<nav><ul><li><a href="/"><strong>s</strong></a></li></ul></nav>`},
		{List(Li(Text("a")), Li(Text("b"), Code("c"))), `<ul><li>a</li><li>b<code>c</code></li></ul>`},
		{Article(Hgroup(H2(Text("t")), P(Date(d)))), `<article><hgroup><h2>t</h2><p><time datetime="2026-10-14">2026-10-14</time></p></hgroup></article>`},
		{Section(H1(Text("a")), H3(Text("b"))), `<section><h1>a</h1><h3>b</h3></section>`},
		{Blockquote(P(Text("q"))), `<blockquote><p>q</p></blockquote>`},
		{Pre("x := <1>"), `<pre>x := &lt;1&gt;</pre>`},
		{P(Text("run "), Code("a<b")), `<p>run <code>a&lt;b</code></p>`},
		{Small(Text("<s>")), `<small>&lt;s&gt;</small>`},
		{A(`/?a="b"`, Text("x")), `<a href="/?a=&#34;b&#34;">x</a>`},
		{DownloadLink("/a.md", `"a".md`, Text("x")), `<a href="/a.md" download="&#34;a&#34;.md" class="secondary">x</a>`},
		{Spread([]Node{Text("a")}, []Node{Text("b"), Text("c")}), `<nav><ul><li>a</li></ul><ul><li>b</li><li>c</li></ul></nav>`},
		{MetaProperty("og:title", "t"), `<meta property="og:title" content="t">`},
		{Script("/x.js"), `<script src="/x.js" defer></script>`},
		{Stylesheet("/a.css?v=1"), `<link rel="stylesheet" href="/a.css?v=1">`},
		{Icon("/favicon.svg", "image/svg+xml"), `<link rel="icon" href="/favicon.svg" type="image/svg+xml">`},
	}
	for _, c := range cases {
		if got := render(t, c.n); got != c.want {
			t.Errorf("got %s, want %s", got, c.want)
		}
	}
}
