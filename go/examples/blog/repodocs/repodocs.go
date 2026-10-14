// Package repodocs embeds the repository's own documents, TODO.md and
// docs/. They sit above the Go module (go/), out of reach of go:embed, so
// go generate copies them into files/ first; the copies are not committed.
// Without them the blog builds and runs, serving no documents.
package repodocs

import (
	"embed"
	"io/fs"
)

//go:generate sh -c "find files -mindepth 1 -maxdepth 1 ! -name .gitignore -exec rm -rf {} + && cp -R ../../../../TODO.md ../../../../docs files/"

//go:embed all:files
var files embed.FS

// FS holds TODO.md and docs/ as copied by go generate, if they were.
var FS = func() fs.FS {
	sub, err := fs.Sub(files, "files")
	if err != nil {
		panic(err)
	}
	return sub
}()
