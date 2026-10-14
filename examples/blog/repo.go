//go:build !(js && wasm)

package main

import (
	"errors"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
)

// findModuleRoot returns the nearest directory at or above dir that holds
// go.mod.
func findModuleRoot(dir string) (string, error) {
	dir, err := filepath.Abs(dir)
	if err != nil {
		return "", err
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir, nil
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			return "", errors.New("no go.mod found in this directory or any parent")
		}
		dir = parent
	}
}

// openRepo opens dir, which must hold go.mod, for -debug. Nothing outside
// dir can be read through the result: os.Root rejects ".." and symbolic
// links that lead out of it.
func openRepo(dir string) (fs.FS, error) {
	if _, err := os.Stat(filepath.Join(dir, "go.mod")); err != nil {
		return nil, fmt.Errorf("-root must be the module root holding go.mod: %w", err)
	}
	r, err := os.OpenRoot(dir)
	if err != nil {
		return nil, err
	}
	return r.FS(), nil
}
