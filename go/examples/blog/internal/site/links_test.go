package site

import (
	"strings"
	"testing"
	"testing/fstest"
)

func TestLinker(t *testing.T) {
	posts, err := LoadPosts(testPosts)
	if err != nil {
		t.Fatal(err)
	}
	docs, err := LoadDocs(testDocs)
	if err != nil {
		t.Fatal(err)
	}
	st := newSite(posts, docs)
	const gh = "https://github.com/podhmo/html-sandbox/blob/main/"
	cases := []struct {
		source, url string
		want        string // "" for not linked
	}{
		{"TODO.md", "https://example.com/a?b#c", "https://example.com/a?b#c"},
		{"TODO.md", "HTTP://example.com", "HTTP://example.com"},
		{"TODO.md", "mailto:a@example.com", "mailto:a@example.com"},
		{"TODO.md", "javascript:alert(1)", ""},
		{"TODO.md", "JavaScript:alert(1)", ""},
		{"TODO.md", "data:text/html,x", ""},
		{"TODO.md", "//example.com/x", "//example.com/x"},
		{"TODO.md", "/posts/hello", "/posts/hello"},
		{"TODO.md", "#to-be-implemented", "#to-be-implemented"},
		{"TODO.md", "docs/ja/design.md", "/docs/ja/design"},
		{"TODO.md", "./docs/ja/design.md#why", "/docs/ja/design#why"},
		{"docs/ja/design.md", "../../TODO.md", "/docs/TODO"},
		{"docs/ja/design.md", "../notes.md", "/docs/notes"},
		{"TODO.md", "go/examples/blog/posts/2026-10-01-old.md", "/posts/old"},
		{postSource(posts[0]), "2026-10-01-old.md", "/posts/old"},
		{postSource(posts[0]), "../../../../docs/ja/design.md", "/docs/ja/design"},
		{"TODO.md", ".claude/skills/todo-md/SKILL.md", gh + ".claude/skills/todo-md/SKILL.md"},
		{"TODO.md", "go/pkg/el/el.go#L10", gh + "go/pkg/el/el.go#L10"},
		{"docs/ja/design.md", "../../go/pkg/", gh + "go/pkg"},
		{"TODO.md", "a b.md", gh + "a%20b.md"},
		{"TODO.md", "../outside.md", ""},
		{"docs/ja/design.md", "../../../x", ""},
	}
	for _, c := range cases {
		got, ok := st.linker(c.source)(c.url)
		if !ok {
			got = ""
		}
		if got != c.want || ok != (c.want != "") {
			t.Errorf("%s: link %q = %q, %v; want %q", c.source, c.url, got, ok, c.want)
		}
	}
}

func TestLinksInPages(t *testing.T) {
	h := newTestServer(t, fstest.MapFS{
		"2026-10-14-hello.md": file("# Hello [`x`](https://x.test)\n\n- [design](../../../../docs/ja/design.md)\n\n[bad](javascript:alert(1)) [ok](#a)"),
	})
	_, body := get(t, h, "/posts/hello")
	for _, want := range []string{
		`<h1>Hello <a href="https://x.test"><code>x</code></a></h1>`,
		`<li><a href="/docs/ja/design">design</a></li>`,
		// The URL holds "(" so this is no link at all.
		`<p>[bad](javascript:alert(1)) <a href="#a">ok</a></p>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("body does not contain %q", want)
		}
	}

	h = newTestServer(t, fstest.MapFS{
		"2026-10-14-hello.md": file("# Hello\n\n[bad](javascript:alert) and [up](../../../../../x)"),
	})
	_, body = get(t, h, "/posts/hello")
	if want := `<p>bad and up</p>`; !strings.Contains(body, want) {
		t.Errorf("body does not contain %q", want)
	}
}
