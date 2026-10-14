// Package posts embeds the blog's posts. It is a package of its own so that
// the posts stay in examples/blog/posts, where -debug also reads them.
package posts

import "embed"

// FS holds every *.md file in this directory.
//
//go:embed *.md
var FS embed.FS
