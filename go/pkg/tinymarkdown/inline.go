package tinymarkdown

import "strings"

// InlineKind tells what an Inline holds.
type InlineKind uint8

const (
	// InlineText is plain text, in Text.
	InlineText InlineKind = iota
	// InlineCode is the content of a `code` span, in Text.
	InlineCode
	// InlineLink is a [text](url) link: Children and URL.
	InlineLink
)

// Inline is a piece of the text held by a Section title, a Paragraph, or a
// List item. Block parsing leaves that text as is; Inlines splits it into
// plain text, code spans, and links.
//
// It is a struct rather than an interface: a document is mostly text and code
// spans, and a slice of interfaces boxed every one of them on the heap. Links
// are rare enough to keep behind a pointer, so that a text or code inline
// stays small.
type Inline struct {
	Kind InlineKind
	Text string // InlineText and InlineCode
	link *linkData
}

// linkData is what an InlineLink adds to an Inline.
type linkData struct {
	Children []Inline
	URL      string
}

// URL is the target of an InlineLink, and "" otherwise.
func (in Inline) URL() string {
	if in.link == nil {
		return ""
	}
	return in.link.URL
}

// Children are the inlines inside an InlineLink, and nil otherwise.
func (in Inline) Children() []Inline {
	if in.link == nil {
		return nil
	}
	return in.link.Children
}

// Text returns plain text.
func Text(s string) Inline { return Inline{Kind: InlineText, Text: s} }

// Code returns the content of a `code` span.
func Code(s string) Inline { return Inline{Kind: InlineCode, Text: s} }

// Link returns a [text](url) link. Children hold the parsed text, which may
// contain code spans but no links. URL is as written; resolving it is up to
// the renderer.
func Link(children []Inline, url string) Inline {
	return Inline{Kind: InlineLink, link: &linkData{Children: children, URL: url}}
}

// Inlines splits s into plain text, code spans, and links.
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
	// Every backquote run and every bracket starts at most one node, and the
	// text around them at most one more each: this upper bound is close
	// enough to save the repeated growth of the slice.
	out := make([]Inline, 0, 1+strings.Count(s, "`")+strings.Count(s, "["))
	text := 0 // start of the plain text not yet emitted
	i := 0
	for i < len(s) {
		// Jump to the next backquote, or bracket, rather than walking
		// every byte: everything before it is plain text.
		j := len(s)
		if b := strings.IndexByte(s[i:], '`'); b >= 0 && i+b < j {
			j = i + b
		}
		if links {
			if b := strings.IndexByte(s[i:], '['); b >= 0 && i+b < j {
				j = i + b
			}
		}
		if j == len(s) {
			break
		}
		i = j
		switch {
		case s[i] == '`':
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
		case links && s[i] == '[':
			label, url, end, ok := link(s, i)
			if !ok {
				i++
				continue
			}
			if text < i {
				out = append(out, Text(s[text:i]))
			}
			out = append(out, Link(inlines(label, false), url))
			i = end
			text = i
		}
	}
	if text < len(s) {
		out = append(out, Text(s[text:]))
	}
	if len(out) == 0 {
		// Keep the nil result the tests and callers expect for no nodes.
		return nil
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
