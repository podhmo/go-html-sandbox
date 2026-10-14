package site

import (
	"context"
	"fmt"
	"io/fs"
	"log/slog"
	"net/http"
	"strings"
	"sync"
	"time"
)

// Live reload for -watch: the server polls the source files, reloads them
// when they change, and sends an SSE "reload" event to every open page.
// Pages load liveReloadScript only in this mode, so a normal run serves no
// JavaScript.
const (
	liveReloadScriptPath = "/_livereload.js"
	liveReloadEventsPath = "/_livereload"
)

// liveReloadScript reloads the page on a "reload" event. It also reloads
// after the connection comes back, which happens when the server restarts.
const liveReloadScript = `(() => {
  let lost = false;
  const es = new EventSource("` + liveReloadEventsPath + `");
  es.addEventListener("reload", () => location.reload());
  es.onerror = () => { lost = true; };
  es.onopen = () => { if (lost) location.reload(); };
})();
`

// EnableLiveReload makes pages load the reload script and turns on the
// events endpoint. Call it before serving.
func (s *Server) EnableLiveReload() {
	s.env.LiveReload = true
	s.reload = newBroadcaster()
}

func (s *Server) handleLiveReloadScript(w http.ResponseWriter, r *http.Request) {
	if s.reload == nil {
		s.renderError(w, r, http.StatusNotFound, "Page not found.", nil)
		return
	}
	h := w.Header()
	h.Set("Content-Type", "text/javascript; charset=utf-8")
	h.Set("Cache-Control", "no-cache")
	w.Write([]byte(liveReloadScript))
}

// handleLiveReloadEvents streams a "reload" event each time the content
// changes, until the client goes away.
func (s *Server) handleLiveReloadEvents(w http.ResponseWriter, r *http.Request) {
	if s.reload == nil {
		s.renderError(w, r, http.StatusNotFound, "Page not found.", nil)
		return
	}
	ch, cancel := s.reload.subscribe()
	defer cancel()

	h := w.Header()
	h.Set("Content-Type", "text/event-stream")
	h.Set("Cache-Control", "no-cache")
	rc := http.NewResponseController(w)
	// Sending something right away fires the client's onopen.
	if _, err := fmt.Fprint(w, "retry: 1000\n\n"); err != nil {
		return
	}
	if err := rc.Flush(); err != nil {
		return
	}
	for {
		select {
		case <-r.Context().Done():
			return
		case <-ch:
			if _, err := fmt.Fprint(w, "event: reload\ndata: \n\n"); err != nil {
				return
			}
			if err := rc.Flush(); err != nil {
				return
			}
		}
	}
}

// broadcaster wakes every subscriber on publish. A subscriber that has not
// caught up yet gets one wake-up, not one per publish.
type broadcaster struct {
	mu   sync.Mutex
	subs map[chan struct{}]struct{}
}

func newBroadcaster() *broadcaster {
	return &broadcaster{subs: map[chan struct{}]struct{}{}}
}

func (b *broadcaster) subscribe() (<-chan struct{}, func()) {
	ch := make(chan struct{}, 1)
	b.mu.Lock()
	b.subs[ch] = struct{}{}
	b.mu.Unlock()
	return ch, func() {
		b.mu.Lock()
		delete(b.subs, ch)
		b.mu.Unlock()
	}
}

func (b *broadcaster) publish() {
	b.mu.Lock()
	defer b.mu.Unlock()
	for ch := range b.subs {
		select {
		case ch <- struct{}{}:
		default:
		}
	}
}

// Source is a set of files to watch: paths in fsys, each a file or a
// directory walked recursively.
type Source struct {
	FS    fs.FS
	Paths []string
}

// Watch polls sources every interval in a new goroutine until ctx is done.
// When any file's name, size, or modification time changes, it calls load
// and, on success, serves the new content and tells open pages to reload.
// On failure the old content stays and the error is logged, so a
// half-written post does not take the site down.
//
// The first snapshot is taken before Watch returns, so any change made
// after that is noticed.
func (s *Server) Watch(ctx context.Context, interval time.Duration, load func() ([]Post, []Doc, error), sources ...Source) error {
	last, err := fingerprint(sources)
	if err != nil {
		return err
	}
	go s.poll(ctx, interval, last, load, sources)
	return nil
}

func (s *Server) poll(ctx context.Context, interval time.Duration, last string, load func() ([]Post, []Doc, error), sources []Source) {
	t := time.NewTicker(interval)
	defer t.Stop()
	for {
		select {
		case <-ctx.Done():
			return
		case <-t.C:
		}
		fp, err := fingerprint(sources)
		if err != nil {
			slog.Error("watch", "error", err)
			continue
		}
		if fp == last {
			continue
		}
		last = fp
		posts, docs, err := load()
		if err != nil {
			slog.Error("reload failed; still serving the previous content", "error", err)
			continue
		}
		s.update(posts, docs)
		s.reload.publish()
		slog.Info("reloaded", "posts", len(posts), "docs", len(docs))
	}
}

// fingerprint describes every file in sources by path, size, and
// modification time. It is cheap enough to poll: no file is read.
func fingerprint(sources []Source) (string, error) {
	var b strings.Builder
	for i, src := range sources {
		for _, root := range src.Paths {
			err := fs.WalkDir(src.FS, root, func(name string, d fs.DirEntry, err error) error {
				if err != nil || d.IsDir() {
					return err
				}
				info, err := d.Info()
				if err != nil {
					return err
				}
				fmt.Fprintf(&b, "%d:%s\t%d\t%d\n", i, name, info.Size(), info.ModTime().UnixNano())
				return nil
			})
			if err != nil {
				return "", err
			}
		}
	}
	return b.String(), nil
}
