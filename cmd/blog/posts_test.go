package main

import (
	"strings"
	"testing"
	"testing/fstest"
	"time"
)

func file(s string) *fstest.MapFile { return &fstest.MapFile{Data: []byte(s)} }

func TestLoadPosts(t *testing.T) {
	fsys := fstest.MapFS{
		"2026-10-01-old.md":      file("# Old\nbody"),
		"2026-10-14-hello.md":    file("intro\n# Hello\n## Sub\n# Second"),
		"2026-10-14-another.md":  file("# Another"),
		"README.txt":             file("ignored: not *.md"),
		"drafts/2026-10-15-x.md": file("ignored: not at the top level"),
	}
	posts, err := loadPosts(fsys)
	if err != nil {
		t.Fatal(err)
	}
	var got []string
	for _, p := range posts {
		got = append(got, p.Date.Format(time.DateOnly)+" "+p.Slug+" "+p.Title)
	}
	want := []string{
		"2026-10-14 another Another",
		"2026-10-14 hello Hello",
		"2026-10-01 old Old",
	}
	if strings.Join(got, "\n") != strings.Join(want, "\n") {
		t.Errorf("got\n%s\nwant\n%s", strings.Join(got, "\n"), strings.Join(want, "\n"))
	}
}

func TestLoadPostsErrors(t *testing.T) {
	cases := []struct {
		name    string
		fsys    fstest.MapFS
		wantErr string
	}{
		{"no date", fstest.MapFS{"hello.md": file("# x")}, "YYYY-MM-DD-slug.md"},
		{"no slug", fstest.MapFS{"2026-10-14.md": file("# x")}, "YYYY-MM-DD-slug.md"},
		{"uppercase slug", fstest.MapFS{"2026-10-14-Hello.md": file("# x")}, "YYYY-MM-DD-slug.md"},
		{"invalid date", fstest.MapFS{"2026-13-01-x.md": file("# x")}, "month out of range"},
		{"duplicate slug", fstest.MapFS{
			"2026-10-01-same.md": file("# a"),
			"2026-10-14-same.md": file("# b"),
		}, `slug "same" is already used`},
		{"no title", fstest.MapFS{"2026-10-14-x.md": file("## only h2")}, "no \"# title\""},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			_, err := loadPosts(c.fsys)
			if err == nil || !strings.Contains(err.Error(), c.wantErr) {
				t.Errorf("got error %v, want it to contain %q", err, c.wantErr)
			}
		})
	}
}
