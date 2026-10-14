package main

import (
	"bufio"
	"context"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestLiveReloadOff(t *testing.T) {
	h := newTestServer(t, testPosts)
	_, body := get(t, h, "/")
	if strings.Contains(body, "<script") {
		t.Error("want no script without -watch")
	}
	for _, p := range []string{liveReloadScriptPath, liveReloadEventsPath} {
		if res, _ := get(t, h, p); res.StatusCode != http.StatusNotFound {
			t.Errorf("%s: status %d, want 404", p, res.StatusCode)
		}
	}
}

func TestLiveReloadOn(t *testing.T) {
	s := newTestServer(t, testPosts)
	s.enableLiveReload()
	for _, p := range []string{"/", "/posts/hello", "/docs/", "/nope"} {
		_, body := get(t, s, p)
		if !strings.Contains(body, `<script src="/_livereload.js" defer></script>`) {
			t.Errorf("%s: missing the live reload script", p)
		}
	}
	res, body := get(t, s, liveReloadScriptPath)
	if ct := res.Header.Get("Content-Type"); ct != "text/javascript; charset=utf-8" || !strings.Contains(body, "EventSource") {
		t.Errorf("script: Content-Type %q, body %.40q", ct, body)
	}
}

func TestLiveReloadEvents(t *testing.T) {
	s := newTestServer(t, testPosts)
	s.enableLiveReload()
	ts := httptest.NewServer(s)
	defer ts.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	req, _ := http.NewRequestWithContext(ctx, http.MethodGet, ts.URL+liveReloadEventsPath, nil)
	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatal(err)
	}
	defer res.Body.Close()
	if ct := res.Header.Get("Content-Type"); ct != "text/event-stream" {
		t.Errorf("Content-Type %q", ct)
	}
	r := bufio.NewReader(res.Body)
	// The first message means the handler has subscribed.
	if got := readEvent(t, r); got != "retry: 1000\n" {
		t.Fatalf("first message %q", got)
	}
	s.reload.publish()
	if got := readEvent(t, r); got != "event: reload\ndata: \n" {
		t.Errorf("event %q", got)
	}
}

// readEvent reads one SSE message, up to the blank line that ends it.
func readEvent(t *testing.T, r *bufio.Reader) string {
	t.Helper()
	var b strings.Builder
	for {
		line, err := r.ReadString('\n')
		if err != nil {
			t.Fatal(err)
		}
		if line == "\n" {
			return b.String()
		}
		b.WriteString(line)
	}
}

func TestWatch(t *testing.T) {
	dir := t.TempDir()
	write := func(name, src string) {
		t.Helper()
		if err := os.WriteFile(filepath.Join(dir, name), []byte(src), 0o644); err != nil {
			t.Fatal(err)
		}
	}
	write("2026-10-14-a.md", "# First")
	fsys := os.DirFS(dir)
	load := func() ([]Post, []Doc, error) {
		posts, err := loadPosts(fsys)
		return posts, nil, err
	}
	posts, _, err := load()
	if err != nil {
		t.Fatal(err)
	}
	s, err := newServer("https://example.com", posts, nil)
	if err != nil {
		t.Fatal(err)
	}
	s.enableLiveReload()
	events, unsubscribe := s.reload.subscribe()
	defer unsubscribe()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	if err := s.watch(ctx, 10*time.Millisecond, load, source{fsys, []string{"."}}); err != nil {
		t.Fatal(err)
	}

	waitFor := func(path, want string) {
		t.Helper()
		deadline := time.Now().Add(3 * time.Second)
		for time.Now().Before(deadline) {
			if _, body := get(t, s, path); strings.Contains(body, want) {
				return
			}
			time.Sleep(10 * time.Millisecond)
		}
		t.Fatalf("%s never contained %q", path, want)
	}

	write("2026-10-15-b.md", "# Second")
	waitFor("/", "Second")
	select {
	case <-events:
	case <-time.After(3 * time.Second):
		t.Fatal("no reload event")
	}

	// A broken file keeps the previous content.
	write("bad name.md", "# Bad")
	time.Sleep(100 * time.Millisecond)
	if _, body := get(t, s, "/"); !strings.Contains(body, "Second") {
		t.Error("previous content should stay after a failed reload")
	}
	if err := os.Remove(filepath.Join(dir, "bad name.md")); err != nil {
		t.Fatal(err)
	}
	write("2026-10-16-c.md", "# Third")
	waitFor("/", "Third")
}
