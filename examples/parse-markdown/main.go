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

	"github.com/podhmo/go-html-sandbox/pkg/tinymarkdown"
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
// so that newlines inside a paragraph (a sign of an unsupported construct
// such as a table) stay visible.
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
				for _, it := range b.Items {
					if _, err = fmt.Fprintf(w, "%s  item %q\n", indent, it); err != nil {
						break
					}
				}
			}
		case tinymarkdown.Quote:
			if _, err = fmt.Fprintf(w, "%squote\n", indent); err == nil {
				err = dump(w, b.Children, depth+1)
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
