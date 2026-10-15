// Command parse-markdown prints the tree that pkg/tinymarkdown builds from
// Markdown files, or from stdin when no file is given. Use it to see how a
// document is understood: anything unsupported shows up as paragraph text.
//
// Usage:
//
//	go run ./examples/parse-markdown TODO.md docs/ja/design.md
//	cat post.md | go run ./examples/parse-markdown
package main

import (
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"strings"

	"github.com/podhmo/html-sandbox/go/pkg/tinymarkdown"
)

func main() {
	flag.Usage = func() {
		fmt.Fprintln(flag.CommandLine.Output(), "usage: parse-markdown [file ...]")
		flag.PrintDefaults()
	}
	flag.Parse()
	if err := run(os.Stdout, os.Stdin, flag.Args()); err != nil {
		slog.Error("parse-markdown", "error", err)
		os.Exit(1)
	}
}

// run dumps each file in paths, or stdin when paths is empty. With more
// than one file, each dump is headed by "== path".
func run(w io.Writer, stdin io.Reader, paths []string) error {
	if len(paths) == 0 {
		src, err := io.ReadAll(stdin)
		if err != nil {
			return err
		}
		return dump(w, tinymarkdown.Parse(string(src)).Children, 0)
	}
	for i, p := range paths {
		src, err := os.ReadFile(p)
		if err != nil {
			return err
		}
		if len(paths) > 1 {
			if i > 0 {
				fmt.Fprintln(w)
			}
			fmt.Fprintf(w, "== %s\n", p)
		}
		if err := dump(w, tinymarkdown.Parse(string(src)).Children, 0); err != nil {
			return err
		}
	}
	return nil
}

// dump writes one block per line, indented by depth. Text is quoted with %q
// so that newlines inside a paragraph (a sign of an unsupported construct)
// stay visible.
func dump(w io.Writer, bs []tinymarkdown.Block, depth int) error {
	indent := strings.Repeat("  ", depth)
	for _, b := range bs {
		var err error
		switch b := b.(type) {
		case tinymarkdown.Section:
			if _, err = fmt.Fprintf(w, "%ssection h%d %q\n", indent, b.Level, b.Title); err == nil {
				err = dump(w, b.Children, depth+1)
			}
		case tinymarkdown.Paragraph:
			_, err = fmt.Fprintf(w, "%sparagraph %q\n", indent, b.Text)
		case tinymarkdown.List:
			if _, err = fmt.Fprintf(w, "%slist\n", indent); err == nil {
				err = dumpItems(w, b.Items, depth+1)
			}
		case tinymarkdown.Quote:
			if _, err = fmt.Fprintf(w, "%squote\n", indent); err == nil {
				err = dump(w, b.Children, depth+1)
			}
		case tinymarkdown.Table:
			if _, err = fmt.Fprintf(w, "%stable %q\n", indent, b.Header); err == nil {
				for _, r := range b.Rows {
					if _, err = fmt.Fprintf(w, "%s  row %q\n", indent, r); err != nil {
						break
					}
				}
			}
		case tinymarkdown.CodeBlock:
			_, err = fmt.Fprintf(w, "%scode %q\n", indent, b.Code)
		default:
			err = fmt.Errorf("unknown block %T", b)
		}
		if err != nil {
			return err
		}
	}
	return nil
}

// dumpItems writes one item per line, with the items nested under an item
// indented below it.
func dumpItems(w io.Writer, items []tinymarkdown.Item, depth int) error {
	indent := strings.Repeat("  ", depth)
	for _, it := range items {
		if _, err := fmt.Fprintf(w, "%sitem %q\n", indent, it.Text); err != nil {
			return err
		}
		if err := dumpItems(w, it.Children, depth+1); err != nil {
			return err
		}
	}
	return nil
}
