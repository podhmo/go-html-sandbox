package main

import (
	"net/http"
	"reflect"
	"strings"
	"testing"
	"testing/fstest"

	sandbox "github.com/podhmo/go-html-sandbox"
)

var testDocs = fstest.MapFS{
	"TODO.md":           file("# TODO\n\n> note\n\n- [ ] **task**: first line\n  second line"),
	"docs/ja/design.md": file("# Design <x>\n\nwhy\n## Use `el`\n- run `go test`\n- ``a ` b``"),
	"docs/notes.md":     file("no heading"),
	"docs/image.svg":    file("<svg/>"),
	"README.md":         file("# not a doc"),
	"other/x.md":        file("# not a doc either"),
}

func TestLoadDocs(t *testing.T) {
	docs, err := loadDocs(testDocs)
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

	if _, err := loadDocs(fstest.MapFS{"TODO.md": file("a"), "docs/TODO.md": file("b")}); err == nil {
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
second line</li>`; !strings.Contains(body, want) {
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

	for _, p := range []string{"/docs/nope", "/docs/TODO.md", "/docs/image"} {
		res, body := get(t, h, p)
		if res.StatusCode != http.StatusNotFound || !strings.Contains(body, "Document not found.") {
			t.Errorf("%s: status %d", p, res.StatusCode)
		}
	}
}

// TestEmbeddedDocs checks that the repository's own documents load.
func TestEmbeddedDocs(t *testing.T) {
	docs, err := loadDocs(sandbox.Docs)
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
