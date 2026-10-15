package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const src = "intro\n# Title\n- a\n  - a1\n- b\n> q\n## Sub\n| x | y |\n| - | - |\n```go\nx := 1\n```\n"

const want = `paragraph "intro"
section h1 "Title"
  list
    item "a"
      item "a1"
    item "b"
  quote
    paragraph "q"
  section h2 "Sub"
    table ["x" "y"]
    code "x := 1"
`

func TestStdin(t *testing.T) {
	var b strings.Builder
	if err := run(&b, strings.NewReader(src), nil); err != nil {
		t.Fatal(err)
	}
	if got := b.String(); got != want {
		t.Errorf("got\n%s\nwant\n%s", got, want)
	}
}

func TestFiles(t *testing.T) {
	dir := t.TempDir()
	a, c := filepath.Join(dir, "a.md"), filepath.Join(dir, "c.md")
	os.WriteFile(a, []byte("# A"), 0o644)
	os.WriteFile(c, []byte("c"), 0o644)

	var b strings.Builder
	if err := run(&b, nil, []string{a, c}); err != nil {
		t.Fatal(err)
	}
	wantFiles := "== " + a + "\nsection h1 \"A\"\n\n== " + c + "\nparagraph \"c\"\n"
	if got := b.String(); got != wantFiles {
		t.Errorf("got\n%s\nwant\n%s", got, wantFiles)
	}

	b.Reset()
	if err := run(&b, nil, []string{a}); err != nil {
		t.Fatal(err)
	}
	if got := b.String(); got != "section h1 \"A\"\n" {
		t.Errorf("single file: got %q", got)
	}

	if err := run(&b, nil, []string{filepath.Join(dir, "missing.md")}); err == nil {
		t.Error("want error for a missing file")
	}
}
