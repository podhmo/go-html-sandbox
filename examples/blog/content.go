package main

import (
	"embed"
	"io/fs"

	sandbox "github.com/podhmo/go-html-sandbox"
)

//go:embed posts/*.md
var embeddedPosts embed.FS

//go:embed favicon.svg
var favicon []byte

// embeddedSources returns the posts and documents built into the binary.
// Every entry point serves these unless told to read files from disk.
func embeddedSources() (posts, docs fs.FS, err error) {
	posts, err = fs.Sub(embeddedPosts, "posts")
	if err != nil {
		return nil, nil, err
	}
	return posts, sandbox.Docs, nil
}
