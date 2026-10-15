// Package tinymarkdown parses a tiny subset of Markdown into a pure-data
// tree. It is a port of go/pkg/tinymarkdown and keeps its behavior,
// including the cases its tests pin down.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines), paragraphs, "> "
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
/// - List is a run of consecutive "- " lines, holding the text after "- ".
///   Indented lines that follow an item continue it, joined with "\n".
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
  List(Array[String])
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
const FENCE = "```"

///|
/// MAX_LEVEL is the deepest heading level recognized.
const MAX_LEVEL = 5

///|
/// SPACES are the characters Go's unicode.IsSpace accepts, so trimming
/// matches strings.TrimSpace.
const SPACES = "\t\n\u{0B}\u{0C}\r \u{85}\u{A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}"

///|
/// trim_space is Go's strings.TrimSpace.
fn trim_space(s : StringView) -> String {
  s.trim(chars=SPACES).to_owned()
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
  let para : Array[String] = []
  let items : Array[String] = []
  let quote : Array[String] = []
  let table : Array[String] = []
  fn flush() {
    if !para.is_empty() {
      out.push(Block(Paragraph(para.join("\n"))))
      para.clear()
    }
    if !items.is_empty() {
      out.push(Block(List(items.copy())))
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

  let code : Array[String] = []
  let mut in_code = false
  for raw in src.split("\n") {
    let line = raw.strip_suffix("\r").unwrap_or(raw).to_owned()
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
      items.push(trim_space(rest))
    } else if !items.is_empty() && line != trimmed && line[0] is (' ' | '\t') {
      // An indented line continues the item above it.
      items[items.length() - 1] += "\n\{trimmed}"
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
/// parse_table parses the lines of a table. It fails, leaving the lines to
/// be a paragraph, unless the second line is a delimiter row with as many
/// cells as the header.
fn parse_table(lines : Array[String]) -> Block? {
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
/// "|" is required by scan; the trailing one is optional.
fn cells(line : String) -> Array[String] {
  let line = line.strip_prefix("|").unwrap_or(line)
  let out = []
  let b = StringBuilder()
  for i = 0; i < line.length(); i = i + 1 {
    if line[i] == '\\' && i + 1 < line.length() && line[i + 1] == '|' {
      b.write_char('|')
      continue i + 2
    } else if line[i] == '|' {
      out.push(trim_space(b.to_string()))
      b.reset()
    } else {
      b.write_view(line[i:i + 1])
    }
  }
  let rest = trim_space(b.to_string())
  if rest != "" {
    out.push(rest)
  }
  out
}

///|
/// is_delimiter reports whether c is a delimiter cell: "---", ":---",
/// ":---:", or "---:", with at least one "-".
fn is_delimiter(c : String) -> Bool {
  let c = c.strip_prefix(":").unwrap_or(c)
  let c = c.strip_suffix(":").unwrap_or(c)
  c != "" && c.trim(chars="-") == ""
}

///|
fn is_heading(line : String) -> Bool {
  let n = line.length() - line.trim_start(chars="#").length()
  1 <= n && n <= MAX_LEVEL && n < line.length() && line[n] == ' '
}

///|
fn parse_heading(line : String) -> Flat {
  let n = line.find(" ").unwrap()
  Heading(n, trim_space(line[n:]))
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
