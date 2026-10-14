// Command blog serves a mobile-first blog from embedded Markdown posts.
package main

import (
	"embed"
	"io/fs"
	"log/slog"
	"os"
)

//go:embed posts/*.md
var postsFS embed.FS

func main() {
	if err := run(); err != nil {
		slog.Error("blog", "error", err)
		os.Exit(1)
	}
}

func run() error {
	sub, err := fs.Sub(postsFS, "posts")
	if err != nil {
		return err
	}
	posts, err := loadPosts(sub)
	if err != nil {
		return err
	}
	slog.Info("loaded posts", "count", len(posts))
	return nil
}
