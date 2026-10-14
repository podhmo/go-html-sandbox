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

// Link is a [text](url) link. Children hold the parsed text, which may
// contain code spans but no links.
type Link struct {
	Children []Inline
	URL      string // as written; resolving it is up to the renderer
}

func (Text) inline() {}
func (Code) inline() {}
func (Link) inline() {}

// Inlines splits s into Text, Code, and Link.
//
// As in CommonMark, a code span opens with a run of backquotes and closes
// with the next run of the same length, so a span opened by two backquotes
// may hold a single one. Line breaks inside a span become spaces, and one
// space is stripped from each end when both ends have one, so that a span
// can start or end with a backquote. A run with no closing run is plain text.
//
// A link is "[", text, "](", a URL, and ")". The text may not contain
// brackets outside code spans, and the URL may not contain spaces,
// parentheses, or line breaks; there is no title. Code spans bind tighter
// than links: a "]" inside a code span does not close the text, and a link
// inside a code span is code. Anything that does not form a link is plain
// text.
func Inlines(s string) []Inline {
	return inlines(s, true)
}

func inlines(s string, links bool) []Inline {
	var out []Inline
	text := 0 // start of the plain text not yet emitted
	emit := func(i int, in Inline) {
		if text < i {
			out = append(out, Text(s[text:i]))
		}
		out = append(out, in)
	}
	for i := 0; i < len(s); {
		switch {
		case s[i] == '`':
			n := backquotes(s, i)
			end := closingRun(s, i+n, n)
			if end < 0 {
				i += n
				continue
			}
			emit(i, Code(codeText(s[i+n:end])))
			i = end + n
			text = i
		case s[i] == '[' && links:
			label, url, end, ok := link(s, i)
			if !ok {
				i++
				continue
			}
			emit(i, Link{Children: inlines(label, false), URL: url})
			i = end
			text = i
		default:
			i++
		}
	}
	if text < len(s) {
		out = append(out, Text(s[text:]))
	}
	return out
}

// link parses a link starting at s[i] == '['. It returns the text, the URL,
// and the index just past the closing ")".
func link(s string, i int) (label, url string, end int, ok bool) {
	j := i + 1
	for ; j < len(s) && s[j] != ']'; j++ {
		switch s[j] {
		case '[':
			return "", "", 0, false
		case '`':
			n := backquotes(s, j)
			if c := closingRun(s, j+n, n); c >= 0 {
				j = c + n - 1
			} else {
				j += n - 1
			}
		}
	}
	if j+1 >= len(s) || s[j+1] != '(' {
		return "", "", 0, false
	}
	label = s[i+1 : j]
	k := j + 2
	for ; k < len(s) && s[k] != ')'; k++ {
		switch s[k] {
		case ' ', '\t', '\n', '(':
			return "", "", 0, false
		}
	}
	if k >= len(s) {
		return "", "", 0, false
	}
	return label, s[j+2 : k], k + 1, true
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
