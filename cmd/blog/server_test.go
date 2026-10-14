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

func TestNotFoundPages(t *testing.T) {
	h := newTestServer(t, testPosts)
	cases := []struct{ path, message string }{
		{"/posts/nope", "Post not found."},
		{"/nope", "Page not found."},
		{"/posts/hello/extra", "Page not found."},
	}
	for _, c := range cases {
		t.Run(c.path, func(t *testing.T) {
			res, body := get(t, h, c.path)
			if res.StatusCode != http.StatusNotFound {
				t.Errorf("status %d", res.StatusCode)
			}
			if ct := res.Header.Get("Content-Type"); ct != "text/html; charset=utf-8" {
				t.Errorf("Content-Type %q", ct)
			}
			for _, want := range []string{"<h1>404 Not Found</h1>", c.message, `<a href="/">Back to all posts</a>`} {
				if !strings.Contains(body, want) {
					t.Errorf("body does not contain %q", want)
				}
			}
		})
	}
}

func TestPanicBecomes500Page(t *testing.T) {
	h := recoverer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
		panic("secret: /etc/internal/path")
	}))
	res, body := get(t, h, "/")
	if res.StatusCode != http.StatusInternalServerError {
		t.Errorf("status %d", res.StatusCode)
	}
	if !strings.Contains(body, "<h1>500 Internal Server Error</h1>") || !strings.Contains(body, "Something went wrong.") {
		t.Errorf("not an error page: %s", body)
	}
	if strings.Contains(body, "secret") {
		t.Error("error page leaks the panic value")
	}
}

func TestFavicon(t *testing.T) {
	res, body := get(t, newTestServer(t, testPosts), "/favicon.svg")
	if res.StatusCode != http.StatusOK {
		t.Fatalf("status %d", res.StatusCode)
	}
	for k, want := range map[string]string{
		"Content-Type":  "image/svg+xml",
		"Cache-Control": "public, max-age=86400",
	} {
		if got := res.Header.Get(k); got != want {
			t.Errorf("%s: got %q, want %q", k, got, want)
		}
	}
	if !strings.HasPrefix(body, "<svg") {
		t.Errorf("not an SVG: %.20q", body)
	}
}
