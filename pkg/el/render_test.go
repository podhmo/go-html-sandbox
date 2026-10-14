package el

import (
	"errors"
	"strings"
	"testing"
)

func render(t *testing.T, n Node, r Renderer) string {
	t.Helper()
	var b strings.Builder
	if err := Render(&b, n, r); err != nil {
		t.Fatalf("Render: %v", err)
	}
	return b.String()
}

func TestHTMLRenderer(t *testing.T) {
	cases := []struct {
		name string
		in   Node
		want string
	}{
		{"text", Text("hello"), "hello"},
		{"text is escaped", Text(`<script>alert("x")</script>`),
			"&lt;script&gt;alert(&#34;x&#34;)&lt;/script&gt;"},
		{"raw is not escaped", Raw("<!doctype html>"), "<!doctype html>"},
		{"empty element", El(P), "<p></p>"},
		{"nested", El(Ul, El(Li, Text("a")), El(Li, Text("b"))),
			"<ul><li>a</li><li>b</li></ul>"},
		{"attributes go into the start tag",
			El(A, Text("top"), Attr(Href, "/"), Attr(Class, "x")),
			`<a href="/" class="x">top</a>`},
		{"attribute value is escaped",
			El(A, Attr(Href, `/" onclick="x`)),
			`<a href="/&#34; onclick=&#34;x"></a>`},
		{"bool attribute", El(Input, BoolAttrNode("hidden")), "<input hidden>"},
		{"void element drops content", El(Br, Text("ignored")), "<br>"},
		{"void element with attrs", El(Meta, Attr(Charset, "utf-8")), `<meta charset="utf-8">`},
		{"nil child is skipped", El(P, nil, Text("x")), "<p>x</p>"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := render(t, c.in, HTMLRenderer{}); got != c.want {
				t.Errorf("got  %q\nwant %q", got, c.want)
			}
		})
	}
}

type unknownNode struct{}

func (unknownNode) node() {}

func TestRenderUnknownNode(t *testing.T) {
	var b strings.Builder
	if err := Render(&b, El(P, unknownNode{}), HTMLRenderer{}); err == nil {
		t.Fatal("want error for unknown node type")
	}
}

type failWriter struct{}

func (failWriter) Write([]byte) (int, error) { return 0, errors.New("boom") }

func TestRenderPropagatesWriteError(t *testing.T) {
	if err := Render(failWriter{}, El(P, Text("x")), HTMLRenderer{}); err == nil {
		t.Fatal("want write error")
	}
}

func TestPlainRenderer(t *testing.T) {
	cases := []struct {
		name string
		in   Node
		want string
	}{
		{"text is not escaped", Text("a < b & c"), "a < b & c"},
		{"raw is dropped", El(Style, Raw("p{color:red}")), ""},
		{"tags and attributes are dropped",
			El(Div, Attr(Class, "x"), BoolAttrNode("hidden"),
				El(P, Text("one ")), El(P, El(A, Attr(Href, "/"), Text("two")))),
			"one two"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := render(t, c.in, PlainRenderer{}); got != c.want {
				t.Errorf("got  %q\nwant %q", got, c.want)
			}
		})
	}
}
