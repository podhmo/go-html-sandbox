package main

import (
	"fmt"
	"io/fs"
	"path"
	"strings"

	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
)

// Doc is a repository document, such as TODO.md or docs/ja/design.md,
// served under /docs/.
type Doc struct {
	Path        string // URL path below /docs/: the file path without "docs/" and ".md"
	Source      string // file path in the repository
	Title       string // the first "#" heading, or Source
	Description string // the first paragraph
	Doc         tinymarkdown.Document
}

// docSources are the files and directories of fsys that hold documents.
// Only these are read, so fsys may be the whole repository on disk.
var docSources = []string{"TODO.md", "docs"}

// loadDocs reads every *.md file in docSources, in that order and then in
// file path order.
func loadDocs(fsys fs.FS) ([]Doc, error) {
	var docs []Doc
	seen := map[string]string{} // Path -> Source
	walk := func(name string, d fs.DirEntry, err error) error {
		if err != nil || d.IsDir() || path.Ext(name) != ".md" {
			return err
		}
		p := strings.TrimPrefix(strings.TrimSuffix(name, ".md"), "docs/")
		if prev, ok := seen[p]; ok {
			return fmt.Errorf("%s: /docs/%s is already used by %s", name, p, prev)
		}
		seen[p] = name

		src, err := fs.ReadFile(fsys, name)
		if err != nil {
			return err
		}
		doc := tinymarkdown.Parse(string(src))
		title, ok := firstTitle(doc)
		if !ok {
			title = name
		}
		docs = append(docs, Doc{Path: p, Source: name, Title: title, Description: firstParagraph(doc.Children), Doc: doc})
		return nil
	}
	for _, root := range docSources {
		if err := fs.WalkDir(fsys, root, walk); err != nil {
			return nil, err
		}
	}
	return docs, nil
}

func docPath(d Doc) string {
	return "/docs/" + d.Path
}
