package main

import (
	"cmp"
	"fmt"
	"io/fs"
	"regexp"
	"slices"
	"time"

	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

// Post is one blog post loaded from a YYYY-MM-DD-slug.md file.
type Post struct {
	Slug  string
	Date  time.Time
	Title string // text of the first "#" heading
	Doc   tinymarkdown.Document
}

var postName = regexp.MustCompile(`^(\d{4}-\d{2}-\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$`)

// loadPosts reads every *.md file at the top of fsys, newest first.
func loadPosts(fsys fs.FS) ([]Post, error) {
	names, err := fs.Glob(fsys, "*.md")
	if err != nil {
		return nil, err
	}
	seen := map[string]string{} // slug -> file name
	posts := make([]Post, 0, len(names))
	for _, name := range names {
		m := postName.FindStringSubmatch(name)
		if m == nil {
			return nil, fmt.Errorf("%s: file name must look like YYYY-MM-DD-slug.md (slug: a-z, 0-9, -)", name)
		}
		date, err := time.Parse(time.DateOnly, m[1])
		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}
		slug := m[2]
		if prev, ok := seen[slug]; ok {
			return nil, fmt.Errorf("%s: slug %q is already used by %s", name, slug, prev)
		}
		seen[slug] = name

		src, err := fs.ReadFile(fsys, name)
		if err != nil {
			return nil, err
		}
		doc := tinymarkdown.Parse(string(src))
		title, ok := firstTitle(doc)
		if !ok {
			return nil, fmt.Errorf("%s: no \"# title\" heading", name)
		}
		posts = append(posts, Post{Slug: slug, Date: date, Title: title, Doc: doc})
	}
	slices.SortFunc(posts, func(a, b Post) int {
		return cmp.Or(b.Date.Compare(a.Date), cmp.Compare(a.Slug, b.Slug))
	})
	return posts, nil
}

// firstTitle returns the title of the first top-level "#" section.
func firstTitle(doc tinymarkdown.Document) (string, bool) {
	for _, b := range doc.Children {
		if s, ok := b.(tinymarkdown.Section); ok && s.Level == 1 {
			return s.Title, true
		}
	}
	return "", false
}
