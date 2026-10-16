// tinymarkdown parses a tiny subset of Markdown into a pure-data tree. The
// parser is MoonBit's (moonbit/pkg/tinymarkdown), built for js by
// moonbit/pkg/tinymarkdown/js into tinymarkdown.mjs (`make ts` in
// ../../../moonbit), which returns objects of the types here. The tests
// are there too: moonbit/pkg/tinymarkdown's, and those of the objects in
// moonbit/pkg/tinymarkdown/js.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines and nest by
// indentation), paragraphs, "> " quotes, "|" tables, and code blocks fenced
// by exactly "```". Anything else is treated as paragraph text. Block
// parsing keeps inline syntax as text; inlines splits out code spans and
// links on request.

export type Document = { children: Block[] };

export type Block = Section | Paragraph | List | Quote | Table | CodeBlock;

// Section is a heading together with everything up to the next heading of
// the same or a shallower level.
export type Section = { kind: "section"; level: number; title: string; children: Block[] };

// Paragraph is a run of consecutive non-blank lines, joined with "\n".
export type Paragraph = { kind: "paragraph"; text: string };

// List is a run of consecutive "- " lines. Each item is nested under the
// nearest item above it whose "- " is indented less.
export type List = { kind: "list"; items: Item[] };

// Item is a list item: the text after "- " and the items nested under it.
// Indented lines that follow an item without "- " continue its text.
export type Item = { text: string; children: Item[] };

// Quote is a run of lines starting with ">", whose content is parsed again
// as a document.
export type Quote = { kind: "quote"; children: Block[] };

// Table is a header row, a delimiter row, and body rows. Every row has as
// many cells as the header; alignment is accepted but ignored.
export type Table = { kind: "table"; header: string[]; rows: string[][] };

// CodeBlock is the verbatim content between "```" fences.
export type CodeBlock = { kind: "code"; code: string };

// Inline is a piece of the text held by a section title, a paragraph, a
// list item, or a table cell.
export type Inline =
  | { kind: "text"; text: string }
  | { kind: "code"; text: string }
  | { kind: "link"; children: Inline[]; url: string };

// parse parses src. It never fails: lines it does not understand become
// paragraph text.
//
// inlines splits s into text, code spans, and links, as Go's Inlines does:
// a code span closes with the next run of as many backquotes, and a link is
// "[text](url)" with no brackets in the text outside code spans and no
// spaces or parentheses in the URL. Code spans bind tighter than links.
export { inlines, parse } from "./tinymarkdown.mjs";
