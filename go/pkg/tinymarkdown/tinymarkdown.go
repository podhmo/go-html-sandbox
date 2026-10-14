// Package tinymarkdown parses a tiny subset of Markdown into a pure-data tree.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines), paragraphs, "> "
// quotes, "|" tables, and code blocks fenced by exactly "```". Anything else
// is treated as paragraph text.
// Block parsing keeps inline syntax as text; Inlines splits out code spans
// and links on request. See docs/sketch/ja/blog.md.
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
	Level    int // 1..5
	Title    string
	Children []Block
}

// Paragraph is a run of consecutive non-blank lines, joined with "\n".
type Paragraph struct {
	Text string
}

// List is a run of consecutive "- " lines. Items hold the text after "- ".
// Indented lines that follow an item continue it, joined with "\n".
type List struct {
	Items []string
}

// Quote is a run of consecutive lines starting with ">". The text after ">"
// and one optional space is parsed again as a document, so a quote may hold
// paragraphs, lists, code blocks, and nested quotes.
type Quote struct {
	Children []Block
}

// Table is a run of consecutive lines starting with "|": a header row, a
// delimiter row such as "| --- | --- |", and body rows. Cells hold their
// text with surrounding spaces trimmed and "\|" unescaped to "|"; inline
// syntax is kept as text, as in Paragraph. Every row has as many cells as
// the header: missing cells are empty and extra ones are dropped. Column
// alignment (":---:") is accepted in the delimiter row but ignored.
type Table struct {
	Header []string
	Rows   [][]string
}

// CodeBlock is the verbatim content between "```" fences, lines joined with
// "\n". Text after the opening fence (a language name) is ignored.
type CodeBlock struct {
	Code string
}

func (Section) block()   {}
func (Paragraph) block() {}
func (List) block()      {}
func (Quote) block()     {}
func (Table) block()     {}
func (CodeBlock) block() {}

const fence = "```"

// maxLevel is the deepest heading level recognized.
const maxLevel = 5

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
	var para, items, quote, table []string
	flush := func() {
		if len(para) > 0 {
			out = append(out, Paragraph{Text: strings.Join(para, "\n")})
			para = nil
		}
		if len(items) > 0 {
			out = append(out, List{Items: items})
			items = nil
		}
		if len(quote) > 0 {
			out = append(out, Quote{Children: Parse(strings.Join(quote, "\n")).Children})
			quote = nil
		}
		if len(table) > 0 {
			if t, ok := parseTable(table); ok {
				out = append(out, t)
			} else {
				out = append(out, Paragraph{Text: strings.Join(table, "\n")})
			}
			table = nil
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
		case strings.HasPrefix(trimmed, "|"):
			if len(para) > 0 || len(items) > 0 || len(quote) > 0 {
				flush()
			}
			table = append(table, trimmed)
		case strings.HasPrefix(trimmed, ">"):
			if len(para) > 0 || len(items) > 0 || len(table) > 0 {
				flush()
			}
			rest := line[strings.IndexByte(line, '>')+1:]
			quote = append(quote, strings.TrimPrefix(rest, " "))
		case strings.HasPrefix(trimmed, "- "):
			if len(para) > 0 || len(quote) > 0 || len(table) > 0 {
				flush()
			}
			items = append(items, strings.TrimSpace(trimmed[2:]))
		case len(items) > 0 && line != trimmed && (line[0] == ' ' || line[0] == '\t'):
			// An indented line continues the item above it.
			items[len(items)-1] += "\n" + trimmed
		default:
			if len(items) > 0 || len(quote) > 0 || len(table) > 0 {
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

// parseTable parses the lines of a table. It fails, leaving the lines to be
// a paragraph, unless the second line is a delimiter row with as many cells
// as the header.
func parseTable(lines []string) (Table, bool) {
	if len(lines) < 2 {
		return Table{}, false
	}
	header := cells(lines[0])
	delim := cells(lines[1])
	if len(delim) != len(header) {
		return Table{}, false
	}
	for _, c := range delim {
		if !isDelimiter(c) {
			return Table{}, false
		}
	}
	t := Table{Header: header}
	for _, line := range lines[2:] {
		row := cells(line)
		if len(row) > len(header) {
			row = row[:len(header)]
		}
		for len(row) < len(header) {
			row = append(row, "")
		}
		t.Rows = append(t.Rows, row)
	}
	return t, true
}

// cells splits a row such as "| a | b |" at unescaped "|". The leading
// "|" is required by scan; the trailing one is optional.
func cells(line string) []string {
	line = strings.TrimPrefix(line, "|")
	var out []string
	var b strings.Builder
	for i := 0; i < len(line); i++ {
		switch {
		case line[i] == '\\' && i+1 < len(line) && line[i+1] == '|':
			b.WriteByte('|')
			i++
		case line[i] == '|':
			out = append(out, strings.TrimSpace(b.String()))
			b.Reset()
		default:
			b.WriteByte(line[i])
		}
	}
	if rest := strings.TrimSpace(b.String()); rest != "" {
		out = append(out, rest)
	}
	return out
}

// isDelimiter reports whether c is a delimiter cell: "---", ":---", ":---:",
// or "---:", with at least one "-".
func isDelimiter(c string) bool {
	c = strings.TrimSuffix(strings.TrimPrefix(c, ":"), ":")
	return c != "" && strings.Trim(c, "-") == ""
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
