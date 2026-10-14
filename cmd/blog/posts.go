package main

import (
	"cmp"
	"fmt"
	"io/fs"
	"regexp"
	"slices"
	"strings"
	"time"

	"github.com/podhmo/go-html-sandbox/pkg/tinyfrontmatter"
	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

// Post is one blog post loaded from a YYYY-MM-DD-slug.md file.
type Post struct {
	Slug        string
	Date        time.Time
	Title       string // front matter "title", or the first "#" heading
	Description string // front matter "description", or the first paragraph
	Doc         tinymarkdown.Document
}

// frontMatterKeys are the keys a post may set; others are reported as typos.
var frontMatterKeys = []string{"title", "description"}

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
		meta, body, err := tinyfrontmatter.Split(string(src))
		if err != nil {
			return nil, fmt.Errorf("%s: %w", name, err)
		}
		for k := range meta {
			if !slices.Contains(frontMatterKeys, k) {
				return nil, fmt.Errorf("%s: unknown front matter key %q (want one of %v)", name, k, frontMatterKeys)
			}
		}
		doc := tinymarkdown.Parse(body)
		title := meta["title"]
		if title == "" {
			title, _ = firstTitle(doc)
		}
		if title == "" {
			return nil, fmt.Errorf("%s: no title (set \"title\" in front matter or start with a \"# title\" heading)", name)
		}
		description := meta["description"]
		if description == "" {
			description = firstParagraph(doc.Children)
		}
		posts = append(posts, Post{Slug: slug, Date: date, Title: title, Description: description, Doc: doc})
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

// firstParagraph returns the first paragraph in document order, with line
// breaks turned into spaces.
func firstParagraph(bs []tinymarkdown.Block) string {
	for _, b := range bs {
		switch b := b.(type) {
		case tinymarkdown.Paragraph:
			return strings.ReplaceAll(b.Text, "\n", " ")
		case tinymarkdown.Section:
			if s := firstParagraph(b.Children); s != "" {
				return s
			}
		}
	}
	return ""
}
