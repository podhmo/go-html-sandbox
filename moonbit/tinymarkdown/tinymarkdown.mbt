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

///|
pub extend Document with Eq::{not_equal, equal}

///|
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
pub extend Block with Eq::{not_equal, equal}

///|
pub extend Block with Debug::{to_repr}

///|
let fence = "```"

///|
/// max_level is the deepest heading level recognized.
let max_level = 5

///|
/// spaces are the characters Go's unicode.IsSpace accepts, so trimming
/// matches strings.TrimSpace.
let spaces = "\t\n\u{0B}\u{0C}\r \u{85}\u{A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}"

///|
/// trim_space is Go's strings.TrimSpace.
fn trim_space(s : StringView) -> String {
  s.trim(chars=spaces).to_owned()
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
  let (children, _) = nest(scan(src), 0, 0)
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
    if para.length() > 0 {
      out.push(Block(Paragraph(para.join("\n"))))
      para.clear()
    }
    if items.length() > 0 {
      out.push(Block(List(items.copy())))
      items.clear()
    }
    if quote.length() > 0 {
      out.push(Block(Quote(parse(quote.join("\n")).children)))
      quote.clear()
    }
    if table.length() > 0 {
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
    let line = (match raw.strip_suffix("\r") {
      Some(v) => v
      None => raw
    }).to_owned()
    let trimmed = trim_space(line)
    if in_code {
      if trimmed == fence {
        out.push(Block(CodeBlock(code.join("\n"))))
        code.clear()
        in_code = false
      } else {
        code.push(line)
      }
      continue
    }
    if trimmed.has_prefix(fence) {
      flush()
      in_code = true
    } else if trimmed == "" {
      flush()
    } else if is_heading(trimmed) {
      flush()
      out.push(parse_heading(trimmed))
    } else if trimmed.has_prefix("|") {
      if para.length() > 0 || items.length() > 0 || quote.length() > 0 {
        flush()
      }
      table.push(trimmed)
    } else if trimmed.has_prefix(">") {
      if para.length() > 0 || items.length() > 0 || table.length() > 0 {
        flush()
      }
      let rest = line[line.find(">").unwrap() + 1:]
      quote.push(
        (match rest.strip_prefix(" ") {
          Some(v) => v
          None => rest
        }).to_owned(),
      )
    } else if trimmed.has_prefix("- ") {
      if para.length() > 0 || quote.length() > 0 || table.length() > 0 {
        flush()
      }
      items.push(trim_space(trimmed[2:]))
    } else if items.length() > 0 &&
      line != trimmed &&
      (line[0] == ' ' || line[0] == '\t') {
      // An indented line continues the item above it.
      items[items.length() - 1] = items[items.length() - 1] + "\n" + trimmed
    } else {
      if items.length() > 0 || quote.length() > 0 || table.length() > 0 {
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
  if lines.length() < 2 {
    return None
  }
  let header = cells(lines[0])
  let delim = cells(lines[1])
  if delim.length() != header.length() || !delim.iter().all(is_delimiter) {
    return None
  }
  let rows = []
  for line in lines[2:] {
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
  let line = match line.strip_prefix("|") {
    Some(v) => v
    None => line
  }
  let out = []
  let b = StringBuilder()
  let mut i = 0
  while i < line.length() {
    if line[i] == '\\' && i + 1 < line.length() && line[i + 1] == '|' {
      b.write_char('|')
      i += 1
    } else if line[i] == '|' {
      out.push(trim_space(b.to_string()))
      b.reset()
    } else {
      b.write_view(line[i:i + 1])
    }
    i += 1
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
  let c = match c.strip_prefix(":") {
    Some(v) => v
    None => c
  }
  let c = match c.strip_suffix(":") {
    Some(v) => v
    None => c
  }
  c != "" && c.trim(chars="-") == ""
}

///|
fn is_heading(line : String) -> Bool {
  let mut n = 0
  while n < line.length() && line[n] == '#' {
    n += 1
  }
  1 <= n && n <= max_level && n < line.length() && line[n] == ' '
}

///|
fn parse_heading(line : String) -> Flat {
  let n = line.find(" ").unwrap()
  Heading(n, trim_space(line[n:]))
}

///|
/// nest turns headings in flat into nested sections. It consumes blocks
/// from flat[i:] until a heading at or above level, returning the children
/// and the index where it stopped.
fn nest(flat : Array[Flat], i : Int32, level : Int32) -> (Array[Block], Int32) {
  let out = []
  let mut i = i
  while i < flat.length() {
    match flat[i] {
      Block(b) => {
        out.push(b)
        i += 1
      }
      Heading(h, _) if h <= level => break
      Heading(h, title) => {
        let (children, next) = nest(flat, i + 1, h)
        out.push(Section(level=h, title~, children~))
        i = next
      }
    }
  }
  (out, i)
}
