package site

import (
	"bytes"
	"fmt"
	"io"
	"log/slog"
	"net/http"
	"net/url"
	"path"
	"strconv"
	"strings"
	"sync/atomic"

	pe "github.com/podhmo/go-html-sandbox/pkg/picoel"
)

// renderer is the single place that picks the output format.
var renderer pe.Renderer = pe.HTMLRenderer{}

// site is the content being served. With -watch it is replaced as a whole
// whenever files change, so a request always sees one consistent version.
type site struct {
	posts  []Post
	bySlug map[string]Post
	docs   []Doc
	byPath map[string]Doc
}

func newSite(posts []Post, docs []Doc) *site {
	st := &site{
		posts:  posts,
		bySlug: make(map[string]Post, len(posts)),
		docs:   docs,
		byPath: make(map[string]Doc, len(docs)),
	}
	for _, p := range posts {
		st.bySlug[p.Slug] = p
	}
	for _, d := range docs {
		st.byPath[d.Path] = d
	}
	return st
}

type Server struct {
	env     pageEnv
	site    atomic.Pointer[site]
	reload  *broadcaster // nil unless live reload is enabled
	handler http.Handler
}

// NewServer serves posts and docs. baseURL is the public origin used for absolute
// URLs in OGP tags, e.g. "https://example.com". Path prefixes are rejected
// because links inside the site are root-relative.
func NewServer(baseURL string, posts []Post, docs []Doc) (*Server, error) {
	u, err := url.Parse(baseURL)
	if err != nil || (u.Scheme != "http" && u.Scheme != "https") || u.Host == "" ||
		(u.Path != "" && u.Path != "/") || u.RawQuery != "" || u.Fragment != "" {
		return nil, fmt.Errorf("base URL must be an http(s) origin such as https://example.com, got %q", baseURL)
	}
	s := &Server{env: pageEnv{BaseURL: strings.TrimSuffix(u.String(), "/")}}
	s.update(posts, docs)
	s.handler = s.recoverer(http.HandlerFunc(s.route))
	return s, nil
}

// route dispatches by hand instead of with http.ServeMux patterns, because
// TinyGo's net/http still has the pre-Go 1.22 ServeMux, which ignores
// methods, {$}, and {name...}. Path values are set with SetPathValue so the
// handlers read them as if a ServeMux had matched.
func (s *Server) route(w http.ResponseWriter, r *http.Request) {
	notFound := func(w http.ResponseWriter, r *http.Request) {
		s.renderError(w, r, http.StatusNotFound, "Page not found.", nil)
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		notFound(w, r)
		return
	}
	p := r.URL.Path
	// Redirect like ServeMux: to the cleaned path, and from a directory
	// without its trailing slash.
	if c := cleanPath(p); c != p || c == "/docs" {
		if c == "/docs" {
			c = "/docs/"
		}
		u := url.URL{Path: c, RawQuery: r.URL.RawQuery}
		http.Redirect(w, r, u.String(), http.StatusTemporaryRedirect)
		return
	}
	slug, isPost := strings.CutPrefix(p, "/posts/")
	switch {
	case p == "/":
		s.handleList(w, r)
	case p == "/docs/":
		s.handleDocList(w, r)
	case p == "/favicon.svg":
		handleFavicon(w, r)
	case p == liveReloadScriptPath:
		s.handleLiveReloadScript(w, r)
	case p == liveReloadEventsPath:
		s.handleLiveReloadEvents(w, r)
	case isPost && strings.HasSuffix(slug, ".md") && !strings.Contains(slug, "/"):
		r.SetPathValue("slug", strings.TrimSuffix(slug, ".md"))
		s.handlePostMarkdown(w, r)
	case isPost && slug != "" && !strings.Contains(slug, "/"):
		r.SetPathValue("slug", slug)
		s.handlePost(w, r)
	case strings.HasPrefix(p, "/docs/") && strings.HasSuffix(p, ".md"):
		r.SetPathValue("path", strings.TrimSuffix(p[len("/docs/"):], ".md"))
		s.handleDocMarkdown(w, r)
	case strings.HasPrefix(p, "/docs/"):
		r.SetPathValue("path", p[len("/docs/"):])
		s.handleDoc(w, r)
	default:
		notFound(w, r)
	}
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.handler.ServeHTTP(w, r)
}

// update replaces the content being served.
func (s *Server) update(posts []Post, docs []Doc) {
	s.site.Store(newSite(posts, docs))
}

func (s *Server) handleList(w http.ResponseWriter, r *http.Request) {
	s.page(w, r, postList(s.env, s.site.Load().posts))
}

func (s *Server) handlePost(w http.ResponseWriter, r *http.Request) {
	p, ok := s.site.Load().bySlug[r.PathValue("slug")]
	if !ok {
		s.renderError(w, r, http.StatusNotFound, "Post not found.", nil)
		return
	}
	s.page(w, r, postPage(s.env, p))
}

func (s *Server) handleDocList(w http.ResponseWriter, r *http.Request) {
	s.page(w, r, docList(s.env, s.site.Load().docs))
}

func (s *Server) handleDoc(w http.ResponseWriter, r *http.Request) {
	d, ok := s.site.Load().byPath[r.PathValue("path")]
	if !ok {
		s.renderError(w, r, http.StatusNotFound, "Document not found.", nil)
		return
	}
	s.page(w, r, docPage(s.env, d))
}

// handlePostMarkdown serves the source of a post, as linked from its page.
func (s *Server) handlePostMarkdown(w http.ResponseWriter, r *http.Request) {
	p, ok := s.site.Load().bySlug[r.PathValue("slug")]
	if !ok {
		s.renderError(w, r, http.StatusNotFound, "Post not found.", nil)
		return
	}
	writeMarkdown(w, p.Markdown)
}

// handleDocMarkdown serves the source of a document, as linked from its page.
func (s *Server) handleDocMarkdown(w http.ResponseWriter, r *http.Request) {
	d, ok := s.site.Load().byPath[r.PathValue("path")]
	if !ok {
		s.renderError(w, r, http.StatusNotFound, "Document not found.", nil)
		return
	}
	writeMarkdown(w, d.Markdown)
}

// writeMarkdown sends src as text. nosniff keeps browsers from guessing that
// Markdown containing tags is HTML.
func writeMarkdown(w http.ResponseWriter, src string) {
	h := w.Header()
	h.Set("Content-Type", "text/markdown; charset=utf-8")
	h.Set("X-Content-Type-Options", "nosniff")
	h.Set("Content-Length", strconv.Itoa(len(src)))
	io.WriteString(w, src)
}

// cleanPath is p without "." and ".." elements and repeated slashes. A
// trailing slash is kept.
func cleanPath(p string) string {
	c := path.Clean("/" + p)
	if strings.HasSuffix(p, "/") && c != "/" {
		c += "/"
	}
	return c
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
func (s *Server) page(w http.ResponseWriter, r *http.Request, n pe.Node) {
	if err := render(w, http.StatusOK, n); err != nil {
		s.renderError(w, r, http.StatusInternalServerError, "Something went wrong.", err)
	}
}

// renderError shows message to the user and logs err, which may hold
// internal details, only on the server.
func (s *Server) renderError(w http.ResponseWriter, r *http.Request, status int, message string, err error) {
	if err != nil {
		slog.ErrorContext(r.Context(), "request failed", "method", r.Method, "path", r.URL.Path, "status", status, "error", err)
	}
	if rerr := render(w, status, errorPage(s.env, status, message)); rerr != nil {
		slog.ErrorContext(r.Context(), "render error page", "error", rerr)
		http.Error(w, message, status)
	}
}

// recoverer turns a panic in h into a 500 error page. Because pages are
// rendered into a buffer first, no partial response has been sent yet.
func (s *Server) recoverer(h http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			v := recover()
			if v == nil {
				return
			}
			if v == http.ErrAbortHandler {
				panic(v)
			}
			s.renderError(w, r, http.StatusInternalServerError, "Something went wrong.", fmt.Errorf("panic: %v", v))
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
