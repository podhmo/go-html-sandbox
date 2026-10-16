// Command blog serves a mobile-first blog from embedded Markdown posts.
package main

import (
	"context"
	"flag"
	"fmt"
	"io/fs"
	"log/slog"
	"net/http"
	"os"
	"time"

	"github.com/podhmo/html-sandbox/go/examples/blog/internal/site"
)

func main() {
	if err := run(); err != nil {
		slog.Error("blog", "error", err)
		os.Exit(1)
	}
}

func run() error {
	addr := flag.String("addr", "localhost:8080", "address to listen on")
	baseURL := flag.String("base-url", "", "public URL of the site for OGP tags (default: http://<addr>)")
	debug := flag.Bool("debug", false, "read posts and docs from files in the parent directory of -root (the repository root) instead of the embedded copies")
	watch := flag.Bool("watch", false, "reload posts and docs when they change and refresh open pages (implies -debug)")
	root := flag.String("root", "", "module root (holding go.mod); -debug reads files from its parent directory, and nothing outside that (default: nearest go.mod above the current directory)")
	flag.Parse()
	if *baseURL == "" {
		*baseURL = "http://" + *addr
	}
	if *watch {
		*debug = true
	}

	postsFS, docsFS := site.EmbeddedSources()
	var err error
	if *debug {
		if *root == "" {
			if *root, err = findModuleRoot("."); err != nil {
				return err
			}
		}
		// posts/, TODO.md, and docs/ sit in the repository root, above the
		// module.
		if docsFS, err = openRepo(*root); err != nil {
			return err
		}
		if postsFS, err = fs.Sub(docsFS, "posts"); err != nil {
			return err
		}
		// A wrong -root would otherwise just show an empty blog.
		if _, err := fs.Stat(postsFS, "."); err != nil {
			return fmt.Errorf("-debug reads posts from posts/ in the parent of -root: %w", err)
		}
	}
	load := func() ([]site.Post, []site.Doc, error) {
		posts, err := site.LoadPosts(postsFS)
		if err != nil {
			return nil, nil, err
		}
		docs, err := site.LoadDocs(docsFS)
		if err != nil {
			return nil, nil, err
		}
		return posts, docs, nil
	}

	posts, docs, err := load()
	if err != nil {
		return err
	}
	s, err := site.NewServer(*baseURL, posts, docs)
	if err != nil {
		return err
	}
	if *watch {
		s.EnableLiveReload()
		err := s.Watch(context.Background(), 500*time.Millisecond, load,
			site.Source{FS: postsFS, Paths: []string{"."}},
			site.Source{FS: docsFS, Paths: site.DocSources},
		)
		if err != nil {
			return err
		}
	}
	slog.Info("listening", "addr", "http://"+*addr, "base-url", *baseURL,
		"posts", len(posts), "docs", len(docs), "debug", *debug, "watch", *watch, "root", *root)
	return http.ListenAndServe(*addr, s)
}
