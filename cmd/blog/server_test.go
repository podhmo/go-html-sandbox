package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"testing/fstest"

	"github.com/podhmo/go-html-sandbox/pkg/el"
)

func newTestServer(t *testing.T, fsys fstest.MapFS) http.Handler {
	t.Helper()
	posts, err := loadPosts(fsys)
	if err != nil {
		t.Fatal(err)
	}
	return newServer(posts)
}

func get(t *testing.T, h http.Handler, path string) (*http.Response, string) {
	t.Helper()
	rec := httptest.NewRecorder()
	h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, path, nil))
	res := rec.Result()
	body, err := io.ReadAll(res.Body)
	if err != nil {
		t.Fatal(err)
	}
	return res, string(body)
}

var testPosts = fstest.MapFS{
	"2026-10-01-old.md":   file("# Old post\nold body"),
	"2026-10-14-hello.md": file("# Hello <script>\n\nfirst\n## Points\n- one\n- two\n```\nx := <1>\n```"),
}

func TestList(t *testing.T) {
	res, body := get(t, newTestServer(t, testPosts), "/")
	if res.StatusCode != http.StatusOK {
		t.Fatalf("status %d", res.StatusCode)
	}
	if ct := res.Header.Get("Content-Type"); ct != "text/html; charset=utf-8" {
		t.Errorf("Content-Type %q", ct)
	}
	if !strings.HasPrefix(body, "<!doctype html>") {
		t.Errorf("missing doctype: %.40q", body)
	}
	hello := strings.Index(body, `<a href="/posts/hello">`)
	old := strings.Index(body, `<a href="/posts/old">`)
	if hello < 0 || old < 0 || hello > old {
		t.Errorf("want links to hello then old, got indexes %d, %d", hello, old)
	}
	if strings.Contains(body, "<script>") {
		t.Error("title must be escaped")
	}
}

func TestPost(t *testing.T) {
	res, body := get(t, newTestServer(t, testPosts), "/posts/hello")
	if res.StatusCode != http.StatusOK {
		t.Fatalf("status %d", res.StatusCode)
	}
	for _, want := range []string{
		`<title>Hello &lt;script&gt; - blog</title>`,
		`<time datetime="2026-10-14">2026-10-14</time>`,
		`<section><h1>Hello &lt;script&gt;</h1><p>first</p><section><h2>Points</h2><ul><li>one</li><li>two</li></ul><pre>x := &lt;1&gt;</pre></section></section>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("body does not contain %q", want)
		}
	}
}

func TestUnknownPost(t *testing.T) {
	res, _ := get(t, newTestServer(t, testPosts), "/posts/nope")
	if res.StatusCode != http.StatusNotFound {
		t.Errorf("status %d", res.StatusCode)
	}
}

func TestPostPageText(t *testing.T) {
	posts, err := loadPosts(testPosts)
	if err != nil {
		t.Fatal(err)
	}
	var b strings.Builder
	if err := el.Render(&b, postPage(posts[0]), el.PlainRenderer{}); err != nil {
		t.Fatal(err)
	}
	want := "blog2026-10-14Hello <script>firstPointsonetwox := <1>Rendered with the Go standard library."
	if !strings.Contains(b.String(), want) {
		t.Errorf("got  %q\nwant it to contain %q", b.String(), want)
	}
}
