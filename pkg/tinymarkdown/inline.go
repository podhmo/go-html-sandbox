package tinymarkdown

import "strings"

// Inline is a piece of the text held by a Section title, a Paragraph, or a
// List item. Block parsing leaves that text as is; Inlines splits it.
type Inline interface {
	inline()
}

// Text is plain text.
type Text string

// Code is the content of a `code` span.
type Code string

func (Text) inline() {}
func (Code) inline() {}

// Inlines splits s into Text and Code. As in CommonMark, a span opens with a
// run of backquotes and closes with the next run of the same length, so a
// span opened by two backquotes may hold a single one. Line breaks inside a
// span become spaces, and one space is stripped from each end when both ends
// have one, so that a span can start or end with a backquote. A run with no
// closing run is plain text.
func Inlines(s string) []Inline {
	var out []Inline
	text := 0 // start of the plain text not yet emitted
	for i := 0; i < len(s); {
		if s[i] != '`' {
			i++
			continue
		}
		n := backquotes(s, i)
		end := closingRun(s, i+n, n)
		if end < 0 {
			i += n
			continue
		}
		if text < i {
			out = append(out, Text(s[text:i]))
		}
		out = append(out, Code(codeText(s[i+n:end])))
		i = end + n
		text = i
	}
	if text < len(s) {
		out = append(out, Text(s[text:]))
	}
	return out
}

// backquotes returns the length of the run of backquotes at s[i:].
func backquotes(s string, i int) int {
	j := i
	for j < len(s) && s[j] == '`' {
		j++
	}
	return j - i
}

// closingRun returns the index of the first run of exactly n backquotes in
// s[from:], or -1.
func closingRun(s string, from, n int) int {
	for j := from; j < len(s); {
		if s[j] != '`' {
			j++
			continue
		}
		m := backquotes(s, j)
		if m == n {
			return j
		}
		j += m
	}
	return -1
}

func codeText(s string) string {
	s = strings.ReplaceAll(s, "\n", " ")
	if len(s) >= 2 && s[0] == ' ' && s[len(s)-1] == ' ' && strings.Trim(s, " ") != "" {
		s = s[1 : len(s)-1]
	}
	return s
}
