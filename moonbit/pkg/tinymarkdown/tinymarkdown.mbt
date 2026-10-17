// Package tinymarkdown parses a tiny subset of Markdown into a pure-data
// tree. It is a port of go/pkg/tinymarkdown and keeps its behavior,
// including the cases its tests pin down.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines and nest by
// indentation), paragraphs, "> "
// quotes, "|" tables, and code blocks fenced by exactly "```". Anything else
// is treated as paragraph text. Block parsing keeps inline syntax as text;
// inlines splits out code spans and links on request.
//
// Go indexes strings by byte and MoonBit by UTF-16 code unit. Every
// character the parser looks for is ASCII, so the two agree.

///|
/// Document is the root of a parsed document. Blocks before the first
/// heading are its direct children.
pub(all) struct Document {
  children : Array[Block]
} derive(Eq, Debug)

// The derived Eq and Debug are meant for == and assert_eq, not as methods;
// the #deprecated extends below (and in inline.mbt) mark the implicitly
// promoted methods as unwanted (warning implicit_impl_as_method), as el does.

///|
#deprecated("Use == and != instead")
pub extend Document with Eq::{not_equal, equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Document with Debug::{to_repr}

///|
/// Block is a block-level node.
///
/// - Section is a heading together with everything up to the next heading
///   of the same or a shallower level (level is 1..5).
/// - Paragraph is a run of consecutive non-blank lines, joined with "\n".
/// - List is a run of consecutive "- " lines. Each item is nested under the
///   nearest item above it whose "- " is indented less, as "b" is under "a"
///   in "- a\n  - b"; with no such item, it is at the top level.
///   Indentation counts leading spaces and tabs, one column each.
/// - Quote is a run of consecutive lines starting with ">". The text after
///   ">" and one optional space is parsed again as a document.
/// - Table is a run of consecutive lines starting with "|": a header row, a
///   delimiter row such as "| --- | --- |", and body rows. Cells are trimmed
///   and "\|" is unescaped to "|"; every row has as many cells as the
///   header. Column alignment is accepted but ignored.
/// - CodeBlock is the verbatim content between "```" fences, lines joined
///   with "\n". Text after the opening fence (a language name) is ignored.
pub(all) enum Block {
  Section(level~ : Int32, title~ : String, children~ : Array[Block])
  Paragraph(String)
  List(Array[Item])
  Quote(Array[Block])
  Table(header~ : Array[String], rows~ : Array[Array[String]])
  CodeBlock(String)
} derive(Eq, Debug)

///|
#deprecated("Use == and != instead")
pub extend Block with Eq::{not_equal, equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Block with Debug::{to_repr}

///|
/// Item is a list item: the text after "- " and the items nested under it.
/// Indented lines that follow an item without "- " continue its text,
/// joined with "\n".
pub(all) struct Item {
  text : String
  children : Array[Item]
} derive(Eq, Debug)

///|
#deprecated("Use == and != instead")
pub extend Item with Eq::{not_equal, equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Item with Debug::{to_repr}

///|
const FENCE = "```"

///|
/// MAX_LEVEL is the deepest heading level recognized.
const MAX_LEVEL = 5

///|
/// trim_space is Go's strings.TrimSpace. It walks the ends itself: `trim` with
/// a character set would build a set (or, for a non-ASCII one, compare each
/// character against every member) on every line and every table cell. It
/// returns a view, as Go's TrimSpace returns a substring, so the caller decides
/// whether the trimmed text has to be copied.
fn trim_space(s : StringView) -> StringView {
  let n = s.length()
  let mut start = 0
  while start < n && is_space_code(s[start]) {
    start = start + 1
  }
  let mut end = n
  while end > start && is_space_code(s[end - 1]) {
    end = end - 1
  }
  s[start:end]
}

///|
/// is_space_code reports whether the UTF-16 code unit c is one of the
/// characters Go's unicode.IsSpace accepts, so that trimming matches
/// strings.TrimSpace. Every one of them is in the Basic Multilingual Plane, so
/// a code unit is enough.
fn is_space_code(c : UInt16) -> Bool {
  if c <= ' ' {
    return (c >= '\t' && c <= '\r') || c == ' '
  }
  match c {
    '\u{85}'
    | '\u{A0}'
    | '\u{1680}'
    | '\u{2028}'
    | '\u{2029}'
    | '\u{202F}'
    | '\u{205F}'
    | '\u{3000}' => true
    _ => c >= '\u{2000}' && c <= '\u{200A}'
  }
}

///|
/// Flat is what scan produces: blocks, with headings kept flat until nest
/// builds sections.
priv enum Flat {
  Block(Block)
  Heading(Int32, String)
}

///|
/// parse parses src. It never fails: lines it does not understand become
/// paragraph text.
pub fn parse(src : String) -> Document {
  let (children, _) = nest(scan(src), from=0, level=0)
  { children, }
}

///|
/// scan splits src into a flat list of blocks, with headings as markers.
fn scan(src : String) -> Array[Flat] {
  let out : Array[Flat] = []
  let para : Array[StringView] = []
  let items : Array[RawItem] = []
  let quote : Array[StringView] = []
  let table : Array[StringView] = []
  fn flush() {
    if !para.is_empty() {
      out.push(Block(Paragraph(para.join("\n"))))
      para.clear()
    }
    if !items.is_empty() {
      out.push(Block(List(nest_items(items, from=0, parent=-1).0)))
      items.clear()
    }
    if !quote.is_empty() {
      out.push(Block(Quote(parse(quote.join("\n")).children)))
      quote.clear()
    }
    if !table.is_empty() {
      match parse_table(table) {
        Some(t) => out.push(Block(t))
        None => out.push(Block(Paragraph(table.join("\n"))))
      }
      table.clear()
    }
  }

  let code : Array[StringView] = []
  let mut in_code = false
  for raw in src.split("\n") {
    // line stays a view: only the lines that are kept are copied to a String.
    let line = raw.strip_suffix("\r").unwrap_or(raw)
    let trimmed = trim_space(line)
    if in_code {
      if trimmed == FENCE {
        out.push(Block(CodeBlock(code.join("\n"))))
        code.clear()
        in_code = false
      } else {
        code.push(line)
      }
      continue
    }
    if trimmed.has_prefix(FENCE) {
      flush()
      in_code = true
    } else if trimmed == "" {
      flush()
    } else if is_heading(trimmed) {
      flush()
      out.push(parse_heading(trimmed))
    } else if trimmed.has_prefix("|") {
      if !para.is_empty() || !items.is_empty() || !quote.is_empty() {
        flush()
      }
      table.push(trimmed)
    } else if trimmed.has_prefix(">") {
      if !para.is_empty() || !items.is_empty() || !table.is_empty() {
        flush()
      }
      let rest = line[line.find(">").unwrap() + 1:]
      quote.push(rest.strip_prefix(" ").unwrap_or(rest).to_owned())
    } else if trimmed is [.. "- ", .. rest] {
      if !para.is_empty() || !quote.is_empty() || !table.is_empty() {
        flush()
      }
      items.push({ indent: indent(line), text: trim_space(rest).to_owned(), })
    } else if !items.is_empty() &&
      line.length() != trimmed.length() &&
      line[0] is (' ' | '\t') {
      // An indented line continues the item above it.
      items[items.length() - 1].text += "\n\{trimmed}"
    } else {
      if !items.is_empty() || !quote.is_empty() || !table.is_empty() {
        flush()
      }
      para.push(trimmed)
    }
  }
  if in_code {
    // An unclosed fence runs to the end of the document.
    out.push(Block(CodeBlock(code.join("\n"))))
  }
  flush()
  out
}

///|
/// RawItem is a list item as scan reads it, kept flat until nest_items
/// builds the nested lists.
priv struct RawItem {
  indent : Int32
  mut text : String
}

///|
/// indent counts the leading spaces and tabs of line.
fn indent(line : StringView) -> Int32 {
  let n = line.length()
  let mut i = 0
  while i < n && (line[i] == ' ' || line[i] == '\t') {
    i = i + 1
  }
  i
}

///|
/// nest_items turns indentation in flat into nested lists. It consumes
/// items from flat[from:] while they are indented deeper than parent,
/// returning them and the index where it stopped.
fn nest_items(
  flat : Array[RawItem],
  from~ : Int32,
  parent~ : Int32,
) -> (Array[Item], Int32) {
  let out = []
  for i = from; i < flat.length() && flat[i].indent > parent; {
    let (children, next) = nest_items(flat, from=i + 1, parent=flat[i].indent)
    out.push({ text: flat[i].text, children, })
    continue next
  } nobreak {
    (out, i)
  }
}

///|
/// parse_table parses the lines of a table. It fails, leaving the lines to
/// be a paragraph, unless the second line is a delimiter row with as many
/// cells as the header.
fn parse_table(lines : Array[StringView]) -> Block? {
  guard lines is [header, delim, .. body] else { return None }
  let header = cells(header)
  let delim = cells(delim)
  guard delim.length() == header.length() && delim.iter().all(is_delimiter) else {
    return None
  }
  let rows = []
  for line in body {
    let row = cells(line)
    row.truncate(header.length())
    for _ in row.length()..<header.length() {
      row.push("")
    }
    rows.push(row)
  }
  Some(Table(header~, rows~))
}

///|
/// cells splits a row such as "| a | b |" at unescaped "|". The leading
/// "|" is required by scan; the trailing one is optional. It jumps from one
/// separator to the next, rather than writing every character to a builder.
fn cells(line : StringView) -> Array[String] {
  let line = line.strip_prefix("|").unwrap_or(line)
  let out = []
  let n = line.length()
  let mut start = 0
  let mut i = 0
  while i < n {
    let j = match line[i:].find("|") {
      None => break
      Some(k) => i + k
    }
    i = j + 1
    // "\|" is a literal "|", not a separator: a backslash always escapes the
    // "|" right after it.
    if j > start && line[j - 1] == '\\' {
      continue
    }
    out.push(trim_space(unescape_cell(line[start:j])).to_owned())
    start = i
  }
  let rest = trim_space(unescape_cell(line[start:]))
  if rest != "" {
    out.push(rest.to_owned())
  }
  out
}

///|
/// unescape_cell turns "\|" into "|". It returns s as is when there is no
/// backslash, so the common cell does not allocate.
fn unescape_cell(s : StringView) -> StringView {
  if s.contains("\\") {
    s.replace_all(old="\\|", new="|")[:]
  } else {
    s
  }
}

///|
/// is_delimiter reports whether c is a delimiter cell: "---", ":---",
/// ":---:", or "---:", with at least one "-".
fn is_delimiter(c : String) -> Bool {
  // Count directly: `trim(chars="-")` builds a character set on every cell.
  let c = c[:]
  let n = c.length()
  let mut start = 0
  let mut end = n
  if start < end && c[start] == ':' {
    start = start + 1
  }
  if end > start && c[end - 1] == ':' {
    end = end - 1
  }
  if start >= end {
    return false
  }
  for i = start; i < end; i = i + 1 {
    if c[i] != '-' {
      return false
    }
  }
  true
}

///|
fn is_heading(line : StringView) -> Bool {
  let n = line.length()
  let mut i = 0
  while i < n && line[i] == '#' {
    i = i + 1
  }
  1 <= i && i <= MAX_LEVEL && i < n && line[i] == ' '
}

///|
fn parse_heading(line : StringView) -> Flat {
  let n = line.find(" ").unwrap()
  Heading(n, trim_space(line[n:]).to_owned())
}

///|
/// nest turns headings in flat into nested sections. It consumes blocks
/// from flat[from:] until a heading at or above level, returning the children
/// and the index where it stopped.
fn nest(
  flat : Array[Flat],
  from~ : Int32,
  level~ : Int32,
) -> (Array[Block], Int32) {
  let out = []
  for i = from; i < flat.length(); {
    match flat[i] {
      Block(b) => {
        out.push(b)
        continue i + 1
      }
      Heading(h, _) if h <= level => break (out, i)
      Heading(h, title) => {
        let (children, next) = nest(flat, from=i + 1, level=h)
        out.push(Section(level=h, title~, children~))
        continue next
      }
    }
  } nobreak {
    (out, i)
  }
}
