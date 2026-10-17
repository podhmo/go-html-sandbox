// Package tinymarkdown parses a tiny subset of Markdown into a pure-data tree.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines and nest by
// indentation), paragraphs, "> "
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

// List is a run of consecutive "- " lines. Each item is nested under the
// nearest item above it whose "- " is indented less, as "b" is under "a" in
// "- a\n  - b"; with no such item, it is at the top level. Indentation
// counts leading spaces and tabs, one column each.
type List struct {
	Items []Item
}

// Item is a list item: the text after "- " and the items nested under it.
// Indented lines that follow an item without "- " continue its text,
// joined with "\n".
type Item struct {
	Text     string
	Children []Item
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
	var para, quote, table []string
	var items []rawItem
	flush := func() {
		if len(para) > 0 {
			out = append(out, Paragraph{Text: strings.Join(para, "\n")})
			para = nil
		}
		if len(items) > 0 {
			list, _ := nestItems(items, 0, -1)
			out = append(out, List{Items: list})
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
			items = append(items, rawItem{indent: indent(line), text: strings.TrimSpace(trimmed[2:])})
		case len(items) > 0 && line != trimmed && (line[0] == ' ' || line[0] == '\t'):
			// An indented line continues the item above it.
			items[len(items)-1].text += "\n" + trimmed
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

// rawItem is a list item as scan reads it, kept flat until nestItems builds
// the nested lists.
type rawItem struct {
	indent int
	text   string
}

// indent counts the leading spaces and tabs of line.
func indent(line string) int {
	return len(line) - len(strings.TrimLeft(line, " \t"))
}

// nestItems turns indentation in flat into nested lists. It consumes items
// from flat[i:] while they are indented deeper than parent, returning them
// and the index where it stopped.
func nestItems(flat []rawItem, i, parent int) ([]Item, int) {
	var out []Item
	for i < len(flat) && flat[i].indent > parent {
		it := Item{Text: flat[i].text}
		it.Children, i = nestItems(flat, i+1, flat[i].indent)
		out = append(out, it)
	}
	return out, i
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
	start, i := 0, 0
	for i < len(line) {
		j := strings.IndexByte(line[i:], '|')
		if j < 0 {
			break
		}
		j += i
		i = j + 1
		// "\|" is a literal "|", not a separator: a backslash always
		// escapes the "|" right after it.
		if j > start && line[j-1] == '\\' {
			continue
		}
		out = append(out, strings.TrimSpace(unescapeCell(line[start:j])))
		start = i
	}
	if rest := strings.TrimSpace(unescapeCell(line[start:])); rest != "" {
		out = append(out, rest)
	}
	return out
}

// unescapeCell turns "\|" into "|". It returns s as is when there is no
// backslash, so the common cell does not allocate.
func unescapeCell(s string) string {
	if !strings.Contains(s, `\`) {
		return s
	}
	return strings.ReplaceAll(s, `\|`, "|")
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
