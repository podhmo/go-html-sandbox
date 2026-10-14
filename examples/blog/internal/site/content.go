// Package site is the blog shared by its entry points: examples/blog (a
// standard HTTP server with -debug and -watch) and examples/blog/workers
// (Cloudflare Workers, built with TinyGo).
package site

import (
	"crypto/sha256"
	_ "embed"
	"encoding/hex"
	"io/fs"

	sandbox "github.com/podhmo/go-html-sandbox"
	"github.com/podhmo/go-html-sandbox/examples/blog/posts"
)

//go:embed favicon.svg
var favicon []byte

// siteCSS holds the rules pico cannot express and the typography tuned
// for Japanese, loaded after pico.
//
//go:embed site.css
var siteCSS []byte

// siteCSSPath carries a hash of siteCSS, so browsers may cache it for long
// and still pick up a new version right after a deploy.
var siteCSSPath = func() string {
	sum := sha256.Sum256(siteCSS)
	return "/site.css?v=" + hex.EncodeToString(sum[:4])
}()

// EmbeddedSources returns the posts and documents built into the binary.
// Every entry point serves these unless told to read files from disk.
func EmbeddedSources() (postsFS, docsFS fs.FS) {
	return posts.FS, sandbox.Docs
}
