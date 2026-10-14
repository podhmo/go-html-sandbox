// Command blog serves a mobile-first blog from embedded Markdown posts.
package main

import (
	"context"
	"embed"
	"flag"
	"fmt"
	"io/fs"
	"log/slog"
	"net/http"
	"os"
	"time"

	sandbox "github.com/podhmo/go-html-sandbox"
)

//go:embed posts/*.md
var embeddedPosts embed.FS

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
	baseURL := flag.String("base-url", "", "public URL of the site for OGP tags (default: http://<addr>)")
	debug := flag.Bool("debug", false, "read posts and docs from files under -root instead of the embedded copies")
	watch := flag.Bool("watch", false, "reload posts and docs when they change and refresh open pages (implies -debug)")
	root := flag.String("root", "", "module root (holding go.mod) that -debug reads files from; nothing outside it is read (default: nearest go.mod above the current directory)")
	flag.Parse()
	if *baseURL == "" {
		*baseURL = "http://" + *addr
	}
	if *watch {
		*debug = true
	}

	postsFS, err := fs.Sub(embeddedPosts, "posts")
	if err != nil {
		return err
	}
	docsFS := fs.FS(sandbox.Docs)
	if *debug {
		if *root == "" {
			if *root, err = findModuleRoot("."); err != nil {
				return err
			}
		}
		repo, err := openRepo(*root)
		if err != nil {
			return err
		}
		docsFS = repo
		if postsFS, err = fs.Sub(repo, "examples/blog/posts"); err != nil {
			return err
		}
		// A wrong -root would otherwise just show an empty blog.
		if _, err := fs.Stat(postsFS, "."); err != nil {
			return fmt.Errorf("-debug reads posts from <root>/examples/blog/posts: %w", err)
		}
	}
	load := func() ([]Post, []Doc, error) {
		posts, err := loadPosts(postsFS)
		if err != nil {
			return nil, nil, err
		}
		docs, err := loadDocs(docsFS)
		if err != nil {
			return nil, nil, err
		}
		return posts, docs, nil
	}

	posts, docs, err := load()
	if err != nil {
		return err
	}
	s, err := newServer(*baseURL, posts, docs)
	if err != nil {
		return err
	}
	if *watch {
		s.enableLiveReload()
		err := s.watch(context.Background(), 500*time.Millisecond, load,
			source{postsFS, []string{"."}},
			source{docsFS, docSources},
		)
		if err != nil {
			return err
		}
	}
	slog.Info("listening", "addr", "http://"+*addr, "base-url", *baseURL,
		"posts", len(posts), "docs", len(docs), "debug", *debug, "watch", *watch, "root", *root)
	return http.ListenAndServe(*addr, s)
}
