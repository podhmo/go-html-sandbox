// Package posts embeds the blog's posts, posts/*.md in the repository root.
// They sit above the Go module (go/), out of reach of go:embed, so go
// generate copies them into files/ first; the copies are not committed.
// Without them the blog builds and runs, serving no posts.
package posts

import (
	"embed"
	"io/fs"
)

//go:generate sh -c "find files -mindepth 1 -maxdepth 1 ! -name .gitignore -exec rm -rf {} + && cp ../../../../posts/*.md files/"

//go:embed all:files
var files embed.FS

// FS holds every *.md file of posts/ as copied by go generate, if they were.
var FS = func() fs.FS {
	sub, err := fs.Sub(files, "files")
	if err != nil {
		panic(err)
	}
	return sub
}()
