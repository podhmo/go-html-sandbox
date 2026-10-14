package site

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"testing/fstest"

	pe "github.com/podhmo/go-html-sandbox/pkg/picoel"
)

func newTestServer(t *testing.T, fsys fstest.MapFS) *Server {
	t.Helper()
	posts, err := LoadPosts(fsys)
	if err != nil {
		t.Fatal(err)
	}
	docs, err := LoadDocs(testDocs)
	if err != nil {
		t.Fatal(err)
	}
	h, err := NewServer("https://example.com", posts, docs)
	if err != nil {
		t.Fatal(err)
	}
	return h
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

func TestPicoOnly(t *testing.T) {
	_, body := get(t, newTestServer(t, testPosts), "/posts/hello")
	if !strings.Contains(body, `<link rel="stylesheet" href="`+pe.StylesheetURL+`">`) {
		t.Error("missing pico stylesheet")
	}
	if strings.Contains(body, "<style") || strings.Contains(body, " style=") {
		t.Error("want no custom CSS")
	}
	for _, want := range []string{`<header class="container">`, `<main class="container">`, `<footer class="container">`} {
		if !strings.Contains(body, want) {
			t.Errorf("body does not contain %q", want)
		}
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
	posts, err := LoadPosts(testPosts)
	if err != nil {
		t.Fatal(err)
	}
	var b strings.Builder
	if err := pe.Render(&b, postPage(pageEnv{BaseURL: "https://example.com"}, posts[0]), pe.PlainRenderer{}); err != nil {
		t.Fatal(err)
	}
	want := `Hello <script> - blog
blog
docs
2026-10-14
Download .md
Hello <script>
first
Points
one
two
x := <1>
Rendered with the Go standard library.
`
	if got := b.String(); got != want {
		t.Errorf("got\n%s\nwant\n%s", got, want)
	}
}

func TestPostMarkdown(t *testing.T) {
	h := newTestServer(t, testPosts)
	res, body := get(t, h, "/posts/hello.md")
	if res.StatusCode != http.StatusOK {
		t.Fatalf("status %d", res.StatusCode)
	}
	if want := string(testPosts["2026-10-14-hello.md"].Data); body != want {
		t.Errorf("got %q, want %q", body, want)
	}
	for k, want := range map[string]string{
		"Content-Type":           "text/markdown; charset=utf-8",
		"X-Content-Type-Options": "nosniff",
	} {
		if got := res.Header.Get(k); got != want {
			t.Errorf("%s %q, want %q", k, got, want)
		}
	}

	_, body = get(t, h, "/posts/hello")
	if want := `<header><nav><ul><li><time datetime="2026-10-14">2026-10-14</time></li></ul><ul><li><small><a href="/posts/hello.md" download="2026-10-14-hello.md" class="secondary">Download .md</a></small></li></ul></nav></header><article>`; !strings.Contains(body, want) {
		t.Errorf("body does not contain %q", want)
	}
}

func TestNotFoundPages(t *testing.T) {
	h := newTestServer(t, testPosts)
	cases := []struct{ path, message string }{
		{"/posts/nope", "Post not found."},
		{"/nope", "Page not found."},
		{"/posts/hello/extra", "Page not found."},
		{"/posts/nope.md", "Post not found."},
		{"/posts/hello/extra.md", "Page not found."},
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
	s, err := NewServer("https://example.com", nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	h := s.recoverer(http.HandlerFunc(func(http.ResponseWriter, *http.Request) {
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

func TestPostPageHeading(t *testing.T) {
	h := newTestServer(t, fstest.MapFS{
		"2026-10-14-fm.md":   file("---\ntitle: From <FM>\ndescription: Short & sweet\n---\nbody"),
		"2026-10-14-both.md": file("---\ntitle: FM title\n---\n# Body heading\nbody"),
	})
	_, body := get(t, h, "/posts/fm")
	for _, want := range []string{
		`<title>From &lt;FM&gt; - blog</title>`,
		`<meta name="description" content="Short &amp; sweet">`,
		`<h1>From &lt;FM&gt;</h1><p>body</p>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("fm: body does not contain %q", want)
		}
	}
	_, body = get(t, h, "/posts/both")
	if !strings.Contains(body, "<title>FM title - blog</title>") {
		t.Error("both: title should come from front matter")
	}
	if strings.Count(body, "<h1>") != 1 || !strings.Contains(body, "<h1>Body heading</h1>") {
		t.Error("both: want exactly the body heading as <h1>")
	}
}

func TestOGP(t *testing.T) {
	h := newTestServer(t, fstest.MapFS{
		"2026-10-14-hello.md": file("---\ndescription: Say \"hi\" & more\n---\n# Hello\nbody"),
	})
	cases := []struct {
		path string
		want []string
	}{
		{"/", []string{
			`<title>blog</title>`,
			`<meta property="og:title" content="blog">`,
			`<meta property="og:type" content="website">`,
			`<meta property="og:url" content="https://example.com/">`,
			`<meta property="og:description" content="Notes rendered with the Go standard library only.">`,
			`<meta property="og:site_name" content="blog">`,
		}},
		{"/posts/hello", []string{
			`<meta property="og:title" content="Hello">`,
			`<meta property="og:type" content="article">`,
			`<meta property="og:url" content="https://example.com/posts/hello">`,
			`<meta property="og:description" content="Say &#34;hi&#34; &amp; more">`,
		}},
	}
	for _, c := range cases {
		t.Run(c.path, func(t *testing.T) {
			_, body := get(t, h, c.path)
			for _, want := range c.want {
				if !strings.Contains(body, want) {
					t.Errorf("body does not contain %q", want)
				}
			}
		})
	}
	t.Run("error pages have no OGP", func(t *testing.T) {
		_, body := get(t, h, "/nope")
		if strings.Contains(body, "og:") {
			t.Error("404 page should not have OGP tags")
		}
	})
}

func TestBaseURL(t *testing.T) {
	cases := []struct {
		in, wantURL string // wantURL empty means an error
	}{
		{"https://example.com", "https://example.com/posts/x"},
		{"https://example.com/", "https://example.com/posts/x"},
		{"https://example.com/blog/", ""},
		{"http://localhost:8080", "http://localhost:8080/posts/x"},
		{"example.com", ""},
		{"ftp://example.com", ""},
		{"https://example.com/?q=1", ""},
		{"", ""},
	}
	posts, err := LoadPosts(fstest.MapFS{"2026-10-14-x.md": file("# x")})
	if err != nil {
		t.Fatal(err)
	}
	for _, c := range cases {
		t.Run(c.in, func(t *testing.T) {
			h, err := NewServer(c.in, posts, nil)
			if c.wantURL == "" {
				if err == nil {
					t.Error("want error")
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			_, body := get(t, h, "/posts/x")
			if want := `<meta property="og:url" content="` + c.wantURL + `">`; !strings.Contains(body, want) {
				t.Errorf("body does not contain %q", want)
			}
		})
	}
}

func TestRedirects(t *testing.T) {
	h := newTestServer(t, testPosts)
	cases := []struct{ path, location string }{
		{"/docs", "/docs/"},
		{"/docs?x=1", "/docs/?x=1"},
		{"//posts/hello", "/posts/hello"},
		{"/posts/../docs/", "/docs/"},
		{"/docs/ja/../TODO", "/docs/TODO"},
	}
	for _, c := range cases {
		t.Run(c.path, func(t *testing.T) {
			rec := httptest.NewRecorder()
			h.ServeHTTP(rec, httptest.NewRequest(http.MethodGet, c.path, nil))
			if rec.Code != http.StatusTemporaryRedirect {
				t.Errorf("status %d", rec.Code)
			}
			if got := rec.Header().Get("Location"); got != c.location {
				t.Errorf("Location %q, want %q", got, c.location)
			}
		})
	}
}
