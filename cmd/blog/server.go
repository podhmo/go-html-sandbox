package main

import (
	"bytes"
	"io"
	"net/http"
	"strconv"

	"github.com/podhmo/go-html-sandbox/pkg/el"
)

// renderer is the single place that picks the output format.
var renderer el.Renderer = el.HTMLRenderer{}

type server struct {
	posts  []Post
	bySlug map[string]Post
}

func newServer(posts []Post) http.Handler {
	s := &server{posts: posts, bySlug: make(map[string]Post, len(posts))}
	for _, p := range posts {
		s.bySlug[p.Slug] = p
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleList)
	mux.HandleFunc("GET /posts/{slug}", s.handlePost)
	return mux
}

func (s *server) handleList(w http.ResponseWriter, r *http.Request) {
	render(w, http.StatusOK, postList(s.posts))
}

func (s *server) handlePost(w http.ResponseWriter, r *http.Request) {
	p, ok := s.bySlug[r.PathValue("slug")]
	if !ok {
		http.NotFound(w, r)
		return
	}
	render(w, http.StatusOK, postPage(p))
}

// render writes a full HTML document. It renders into a buffer first so that
// nothing is sent until rendering has succeeded.
func render(w http.ResponseWriter, status int, n el.Node) error {
	var b bytes.Buffer
	b.WriteString("<!doctype html>\n")
	if err := el.Render(&b, n, renderer); err != nil {
		return err
	}
	h := w.Header()
	h.Set("Content-Type", "text/html; charset=utf-8")
	h.Set("Content-Length", strconv.Itoa(b.Len()))
	w.WriteHeader(status)
	_, err := io.Copy(w, &b)
	return err
}
