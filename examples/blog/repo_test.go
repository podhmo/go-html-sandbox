//go:build !(js && wasm)

package main

import (
	"io/fs"
	"os"
	"path/filepath"
	"testing"
)

func TestFindModuleRoot(t *testing.T) {
	dir := t.TempDir()
	sub := filepath.Join(dir, "a", "b")
	if err := os.MkdirAll(sub, 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "go.mod"), []byte("module x\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := findModuleRoot(sub)
	if err != nil {
		t.Fatal(err)
	}
	if want, _ := filepath.EvalSymlinks(dir); got != dir && got != want {
		t.Errorf("got %s, want %s", got, dir)
	}
}

func TestOpenRepo(t *testing.T) {
	outside := t.TempDir()
	if err := os.WriteFile(filepath.Join(outside, "secret.md"), []byte("# secret"), 0o644); err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	if _, err := openRepo(dir); err == nil {
		t.Error("want error for a directory without go.mod")
	}

	if err := os.WriteFile(filepath.Join(dir, "go.mod"), []byte("module x\n"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "TODO.md"), []byte("# TODO"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, filepath.Join(dir, "docs")); err != nil {
		t.Skip("symlinks unavailable:", err)
	}
	repo, err := openRepo(dir)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := fs.ReadFile(repo, "TODO.md"); err != nil {
		t.Errorf("reading inside the root: %v", err)
	}
	for _, name := range []string{"docs/secret.md", "../" + filepath.Base(outside) + "/secret.md"} {
		if _, err := fs.ReadFile(repo, name); err == nil {
			t.Errorf("%s: read a file outside the root", name)
		}
	}
	if _, err := loadDocs(repo); err == nil {
		t.Error("loadDocs: want error for docs/ linking outside the root")
	}
}
