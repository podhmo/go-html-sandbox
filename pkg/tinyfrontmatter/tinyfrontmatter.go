// Package tinyfrontmatter splits a tiny front matter block from a document.
//
// The block starts with a "---" line at the very beginning of the document
// and ends with the next "---" line. In between, each non-blank line is
// "key: value". The value is everything after the first ":", trimmed; one
// pair of matching surrounding quotes ("..." or '...') is removed. Nothing
// else of YAML is supported.
package tinyfrontmatter

import (
	"fmt"
	"strings"
)

const delimiter = "---"

// Split returns the front matter of src and the rest of the document. If src
// does not start with a "---" line, meta is nil and body is src unchanged.
func Split(src string) (meta map[string]string, body string, err error) {
	first, rest, _ := strings.Cut(src, "\n")
	if trimLine(first) != delimiter {
		return nil, src, nil
	}
	meta = map[string]string{}
	lineno := 1
	for rest != "" {
		var line string
		line, rest, _ = strings.Cut(rest, "\n")
		lineno++
		line = trimLine(line)
		switch line {
		case delimiter:
			return meta, rest, nil
		case "":
			continue
		}
		key, value, ok := strings.Cut(line, ":")
		key = strings.TrimSpace(key)
		if !ok || key == "" {
			return nil, "", fmt.Errorf("tinyfrontmatter: line %d: want \"key: value\", got %q", lineno, line)
		}
		if _, dup := meta[key]; dup {
			return nil, "", fmt.Errorf("tinyfrontmatter: line %d: duplicate key %q", lineno, key)
		}
		meta[key] = unquote(strings.TrimSpace(value))
	}
	return nil, "", fmt.Errorf("tinyfrontmatter: no closing %q", delimiter)
}

func trimLine(s string) string {
	return strings.TrimRight(s, " \t\r")
}

func unquote(s string) string {
	if len(s) >= 2 && (s[0] == '"' || s[0] == '\'') && s[len(s)-1] == s[0] {
		return s[1 : len(s)-1]
	}
	return s
}
