// Command blog serves a mobile-first blog from embedded Markdown posts.
package main

import (
	"embed"
	"flag"
	"io/fs"
	"log/slog"
	"net/http"
	"os"
)

//go:embed posts/*.md
var postsFS embed.FS

//go:embed favicon.svg
var favicon []byte

func main() {
	if err := run(); err != nil {
		slog.Error("blog", "error", err)
		os.Exit(1)
	}
}

func run() error {
	addr := flag.String("addr", "localhost:8080", "address to listen on")
	flag.Parse()

	sub, err := fs.Sub(postsFS, "posts")
	if err != nil {
		return err
	}
	posts, err := loadPosts(sub)
	if err != nil {
		return err
	}
	slog.Info("listening", "addr", "http://"+*addr, "posts", len(posts))
	return http.ListenAndServe(*addr, newServer(posts))
}
