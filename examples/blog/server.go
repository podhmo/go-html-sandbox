package main

import (
	"bytes"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"strconv"
	"strings"

	pe "github.com/podhmo/go-html-sandbox/pkg/picoel"
)

// renderer is the single place that picks the output format.
var renderer pe.Renderer = pe.HTMLRenderer{}

type server struct {
	baseURL string // absolute, without a trailing slash
	posts   []Post
	bySlug  map[string]Post
	docs    []Doc
	byPath  map[string]Doc
}

// newServer serves posts and docs. baseURL is the public origin used for absolute
// URLs in OGP tags, e.g. "https://example.com". Path prefixes are rejected
// because links inside the site are root-relative.
func newServer(baseURL string, posts []Post, docs []Doc) (http.Handler, error) {
	u, err := url.Parse(baseURL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" ||
		(u.Path != "" && u.Path != "/") || u.RawQuery != "" || u.Fragment != "" {
		return nil, fmt.Errorf("base URL must be an http(s) origin such as https://example.com, got %q", baseURL)
	}
	s := &server{
		baseURL: strings.TrimSuffix(u.String(), "/"),
		posts:   posts,
		bySlug:  make(map[string]Post, len(posts)),
		docs:    docs,
		byPath:  make(map[string]Doc, len(docs)),
	}
	for _, p := range posts {
		s.bySlug[p.Slug] = p
	}
	for _, d := range docs {
		s.byPath[d.Path] = d
	}
	mux := http.NewServeMux()
	mux.HandleFunc("GET /{$}", s.handleList)
	mux.HandleFunc("GET /posts/{slug}", s.handlePost)
	mux.HandleFunc("GET /docs/{$}", s.handleDocList)
	mux.HandleFunc("GET /docs/{path...}", s.handleDoc)
	mux.HandleFunc("GET /favicon.svg", handleFavicon)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		renderError(w, r, http.StatusNotFound, "Page not found.", nil)
	})
	return recoverer(mux), nil
}

func (s *server) handleList(w http.ResponseWriter, r *http.Request) {
	page(w, r, postList(s.baseURL, s.posts))
}

func (s *server) handlePost(w http.ResponseWriter, r *http.Request) {
	p, ok := s.bySlug[r.PathValue("slug")]
	if !ok {
		renderError(w, r, http.StatusNotFound, "Post not found.", nil)
		return
	}
	page(w, r, postPage(s.baseURL, p))
}

func (s *server) handleDocList(w http.ResponseWriter, r *http.Request) {
	page(w, r, docList(s.baseURL, s.docs))
}

func (s *server) handleDoc(w http.ResponseWriter, r *http.Request) {
	d, ok := s.byPath[r.PathValue("path")]
	if !ok {
		renderError(w, r, http.StatusNotFound, "Document not found.", nil)
		return
	}
	page(w, r, docPage(s.baseURL, d))
}

// handleFavicon serves the embedded icon. Embedded files have no
// modification time, so it is written directly rather than via ServeContent.
func handleFavicon(w http.ResponseWriter, r *http.Request) {
	h := w.Header()
	h.Set("Content-Type", "image/svg+xml")
	h.Set("Cache-Control", "public, max-age=86400")
	h.Set("Content-Length", strconv.Itoa(len(favicon)))
	w.Write(favicon)
}

// page renders n with status 200, or an error page if rendering fails.
func page(w http.ResponseWriter, r *http.Request, n pe.Node) {
	if err := render(w, http.StatusOK, n); err != nil {
		renderError(w, r, http.StatusInternalServerError, "Something went wrong.", err)
	}
}

// renderError shows message to the user and logs err, which may hold
// internal details, only on the server.
func renderError(w http.ResponseWriter, r *http.Request, status int, message string, err error) {
	if err != nil {
		slog.ErrorContext(r.Context(), "request failed", "method", r.Method, "path", r.URL.Path, "status", status, "error", err)
	}
	if rerr := render(w, status, errorPage(status, message)); rerr != nil {
		slog.ErrorContext(r.Context(), "render error page", "error", rerr)
		http.Error(w, message, status)
	}
}

// recoverer turns a panic in h into a 500 error page. Because pages are
// rendered into a buffer first, no partial response has been sent yet.
func recoverer(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			renderError(w, r, http.StatusInternalServerError, "Something went wrong.", fmt.Errorf("panic: %v", v))
		}()
		h.ServeHTTP(w, r)
	})
}

// render writes a full HTML document. It renders into a buffer first so that
// nothing is sent until rendering has succeeded.
func render(w http.ResponseWriter, status int, n pe.Node) error {
	var b bytes.Buffer
	b.WriteString("<!doctype html>\n")
	if err := pe.Render(&b, n, renderer); err != nil {
		return err
	}
	h := w.Header()
	h.Set("Content-Type", "text/html; charset=utf-8")
	h.Set("Content-Length", strconv.Itoa(b.Len()))
	w.WriteHeader(status)
	_, err := io.Copy(w, &b)
	return err
}
