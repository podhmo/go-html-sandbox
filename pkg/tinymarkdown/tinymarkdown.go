// Package tinymarkdown parses a tiny subset of Markdown into a pure-data tree.
//
// Supported: headings "#" to "###" (which open nested sections), "- " list
// items, paragraphs, and code blocks fenced by exactly "```". Anything else is treated as paragraph text. Inline syntax is
// not interpreted. See docs/sketch/ja/blog.md.
package tinymarkdown

import "strings"

// Document is the root of a parsed document. Blocks before the first
// heading are its direct children.
type Document struct {
	Children []Block
}

// Block is a marker interface for block-level nodes.
type Block interface {
	block()
}

// Section is a heading together with everything up to the next heading of
// the same or a shallower level.
type Section struct {
	Level    int // 1..3
	Title    string
	Children []Block
}

// Paragraph is a run of consecutive non-blank lines, joined with "\n".
type Paragraph struct {
	Text string
}

// List is a run of consecutive "- " lines. Items hold the text after "- ".
type List struct {
	Items []string
}

// CodeBlock is the verbatim content between "```" fences, lines joined with
// "\n". Text after the opening fence (a language name) is ignored.
type CodeBlock struct {
	Code string
}

func (Section) block()   {}
func (Paragraph) block() {}
func (List) block()      {}
func (CodeBlock) block() {}

const fence = "```"

// maxLevel is the deepest heading level recognized.
const maxLevel = 3

// heading is a parsed heading line, kept flat until nest builds sections.
type heading struct {
	level int
	title string
}

func (heading) block() {}

// Parse parses src. It never fails: lines it does not understand become
// paragraph text.
func Parse(src string) Document {
	children, _ := nest(scan(src), 0, 0)
	return Document{Children: children}
}

// scan splits src into a flat list of blocks, with headings as markers.
func scan(src string) []Block {
	var out []Block
	var para, items []string
	flush := func() {
		if len(para) > 0 {
			out = append(out, Paragraph{Text: strings.Join(para, "\n")})
			para = nil
		}
		if len(items) > 0 {
			out = append(out, List{Items: items})
			items = nil
		}
	}
	var code []string
	inCode := false
	for line := range strings.SplitSeq(src, "\n") {
		line = strings.TrimSuffix(line, "\r")
		trimmed := strings.TrimSpace(line)
		if inCode {
			if trimmed == fence {
				out = append(out, CodeBlock{Code: strings.Join(code, "\n")})
				code, inCode = nil, false
			} else {
				code = append(code, line)
			}
			continue
		}
		switch {
		case strings.HasPrefix(trimmed, fence):
			flush()
			inCode = true
		case trimmed == "":
			flush()
		case isHeading(trimmed):
			flush()
			out = append(out, parseHeading(trimmed))
		case strings.HasPrefix(trimmed, "- "):
			if len(para) > 0 {
				flush()
			}
			items = append(items, strings.TrimSpace(trimmed[2:]))
		default:
			if len(items) > 0 {
				flush()
			}
			para = append(para, trimmed)
		}
	}
	if inCode {
		// An unclosed fence runs to the end of the document.
		out = append(out, CodeBlock{Code: strings.Join(code, "\n")})
	}
	flush()
	return out
}

func isHeading(line string) bool {
	n := strings.IndexFunc(line, func(r rune) bool { return r != '#' })
	return 1 <= n && n <= maxLevel && line[n] == ' '
}

func parseHeading(line string) heading {
	n := strings.IndexByte(line, ' ')
	return heading{level: n, title: strings.TrimSpace(line[n:])}
}

// nest turns headings in flat into nested sections. It consumes blocks from
// flat[i:] until a heading at or above level, returning the children and the
// index where it stopped.
func nest(flat []Block, i, level int) ([]Block, int) {
	var out []Block
	for i < len(flat) {
		h, ok := flat[i].(heading)
		if !ok {
			out = append(out, flat[i])
			i++
			continue
		}
		if h.level <= level {
			break
		}
		sec := Section{Level: h.level, Title: h.title}
		sec.Children, i = nest(flat, i+1, h.level)
		out = append(out, sec)
	}
	return out, i
}
