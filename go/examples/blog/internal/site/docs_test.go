package site

import (
	"io/fs"
	"net/http"
	"reflect"
	"strings"
	"testing"
	"testing/fstest"
)

var testDocs = fstest.MapFS{
	"TODO.md":           file("# TODO\n\n> note\n\n- [ ] **task**: first line\n  second line\n  - [x] child"),
	"docs/ja/design.md": file("# Design <x>\n\nwhy\n## Use `el`\n- run `go test`\n- ``a ` b``"),
	"docs/notes.md":     file("no heading"),
	"docs/image.svg":    file("<svg/>"),
	"README.md":         file("# not a doc"),
	"other/x.md":        file("# not a doc either"),
}

func TestLoadDocs(t *testing.T) {
	docs, err := LoadDocs(testDocs)
	if err != nil {
		t.Fatal(err)
	}
	type row struct{ Path, Source, Title, Description string }
	var got []row
	for _, d := range docs {
		got = append(got, row{d.Path, d.Source, d.Title, d.Description})
	}
	want := []row{
		{"TODO", "TODO.md", "TODO", ""},
		{"ja/design", "docs/ja/design.md", "Design <x>", "why"},
		{"notes", "docs/notes.md", "docs/notes.md", "no heading"},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("got %v\nwant %v", got, want)
	}

	if _, err := LoadDocs(fstest.MapFS{"TODO.md": file("a"), "docs/TODO.md": file("b")}); err == nil {
		t.Error("want error for two files mapped to /docs/TODO")
	}
}

func TestDocPages(t *testing.T) {
	h := newTestServer(t, testPosts)

	res, body := get(t, h, "/docs/")
	if res.StatusCode != http.StatusOK {
		t.Fatalf("list: status %d", res.StatusCode)
	}
	for _, want := range []string{
		`<a href="/docs/TODO">TODO</a>`,
		`<a href="/docs/ja/design">Design &lt;x&gt;</a>`,
		`<p>docs/ja/design.md</p>`,
	} {
		if !strings.Contains(body, want) {
			t.Errorf("list: body does not contain %q", want)
		}
	}

	_, body = get(t, h, "/docs/TODO")
	if want := `<li>[ ] **task**: first line
second line<ul><li>[x] child</li></ul></li>`; !strings.Contains(body, want) {
		t.Errorf("TODO: body does not contain %q", want)
	}

	if want := `<blockquote><p>note</p></blockquote>`; !strings.Contains(body, want) {
		t.Errorf("TODO: body does not contain %q", want)
	}

	_, body = get(t, h, "/docs/ja/design")
	if want := `<h2>Use <code>el</code></h2><ul><li>run <code>go test</code></li><li><code>a ` + "`" + ` b</code></li></ul>`; !strings.Contains(body, want) {
		t.Errorf("design: body does not contain %q", want)
	}

	_, body = get(t, h, "/docs/notes")
	if !strings.Contains(body, `<h1>docs/notes.md</h1><p>no heading</p>`) {
		t.Error("notes: want the file path as <h1>")
	}

	for _, p := range []string{"/docs/nope", "/docs/nope.md", "/docs/image", "/docs/image.svg"} {
		res, body := get(t, h, p)
		if res.StatusCode != http.StatusNotFound || !strings.Contains(body, "Document not found.") {
			t.Errorf("%s: status %d", p, res.StatusCode)
		}
	}
}

func TestDocMarkdown(t *testing.T) {
	h := newTestServer(t, testPosts)
	for _, c := range []struct{ path, want string }{
		{"/docs/TODO.md", "# TODO\n\n> note\n\n- [ ] **task**: first line\n  second line\n  - [x] child"},
		{"/docs/ja/design.md", "# Design <x>\n\nwhy\n## Use `el`\n- run `go test`\n- ``a ` b``"},
	} {
		res, body := get(t, h, c.path)
		if res.StatusCode != http.StatusOK || body != c.want {
			t.Errorf("%s: status %d, body %q", c.path, res.StatusCode, body)
		}
		if ct := res.Header.Get("Content-Type"); ct != "text/markdown; charset=utf-8" {
			t.Errorf("%s: Content-Type %q", c.path, ct)
		}
	}

	_, body := get(t, h, "/docs/ja/design")
	if want := `<ul><li><small><a href="/docs/ja/design.md" download="design.md" class="secondary">Download .md</a></small></li></ul></nav></header><article>`; !strings.Contains(body, want) {
		t.Errorf("design: body does not contain %q", want)
	}
}

// TestEmbeddedDocs checks that the repository's own documents load. They
// are embedded only after go generate copies them in.
func TestEmbeddedDocs(t *testing.T) {
	_, docsFS := EmbeddedSources()
	if _, err := fs.Stat(docsFS, "TODO.md"); err != nil {
		t.Skip("documents not copied in; run go generate ./...")
	}
	docs, err := LoadDocs(docsFS)
	if err != nil {
		t.Fatal(err)
	}
	paths := map[string]bool{}
	for _, d := range docs {
		paths[d.Path] = true
	}
	for _, p := range []string{"TODO", "ja/design", "sketch/ja/blog"} {
		if !paths[p] {
			t.Errorf("missing /docs/%s in %v", p, paths)
		}
	}
}

// TestLoadDocsMissing checks that sources missing from the FS are skipped.
func TestLoadDocsMissing(t *testing.T) {
	docs, err := LoadDocs(fstest.MapFS{})
	if err != nil {
		t.Fatal(err)
	}
	if len(docs) != 0 {
		t.Errorf("got %d docs, want none", len(docs))
	}
}
