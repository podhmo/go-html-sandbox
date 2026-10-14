// Package site is the blog shared by its entry points: examples/blog (a
// standard HTTP server with -debug and -watch) and examples/blog/workers
// (Cloudflare Workers, built with TinyGo).
package site

import (
	_ "embed"
	"io/fs"

	sandbox "github.com/podhmo/go-html-sandbox"
	"github.com/podhmo/go-html-sandbox/examples/blog/posts"
)

//go:embed favicon.svg
var favicon []byte

// EmbeddedSources returns the posts and documents built into the binary.
// Every entry point serves these unless told to read files from disk.
func EmbeddedSources() (postsFS, docsFS fs.FS) {
	return posts.FS, sandbox.Docs
}
