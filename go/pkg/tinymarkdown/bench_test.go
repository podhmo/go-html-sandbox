package tinymarkdown

import (
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// largestDoc reads the largest Markdown file in the repository's docs/ and
// posts/. It is the heaviest input the blog parses, and stands in for a page
// when profiling Parse and Inlines. Benchmarks skip when the repository is
// not around the module (the paths are relative to this package).
func largestDoc(tb testing.TB) string {
	tb.Helper()
	var bestPath string
	var bestSize int64
	for _, root := range []string{"../../../docs", "../../../posts"} {
		err := filepath.WalkDir(root, func(path string, d fs.DirEntry, err error) error {
			if err != nil || d.IsDir() || !strings.HasSuffix(path, ".md") {
				return nil
			}
			info, err := d.Info()
			if err != nil {
				return nil
			}
			if info.Size() > bestSize {
				bestPath, bestSize = path, info.Size()
			}
			return nil
		})
		if err != nil {
			tb.Logf("walk %s: %v", root, err)
		}
	}
	if bestPath == "" {
		tb.Skip("no Markdown under ../../../docs or ../../../posts")
	}
	src, err := os.ReadFile(bestPath)
	if err != nil {
		tb.Fatal(err)
	}
	tb.Logf("input: %s (%d bytes)", bestPath, len(src))
	return string(src)
}

func BenchmarkParse(b *testing.B) {
	src := largestDoc(b)
	b.SetBytes(int64(len(src)))
	b.ReportAllocs()
	for b.Loop() {
		_ = Parse(src)
	}
}

func BenchmarkInlines(b *testing.B) {
	src := largestDoc(b)
	b.SetBytes(int64(len(src)))
	b.ReportAllocs()
	for b.Loop() {
		_ = Inlines(src)
	}
}
