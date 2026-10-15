///|
/// escape_to writes s to sb escaped the way Go's html.EscapeString does,
/// so that pages match the Go blog byte for byte.
fn escape_to(sb : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '&' => sb.write_string("&amp;")
      '\'' => sb.write_string("&#39;")
      '"' => sb.write_string("&#34;")
      _ => sb.write_char(c)
    }
  }
}

///|
/// is_void reports whether elements named name have no content and no end
/// tag.
fn is_void(name : Tag) -> Bool {
  match name.0 {
    "area"
    | "base"
    | "br"
    | "col"
    | "embed"
    | "hr"
    | "img"
    | "input"
    | "link"
    | "meta"
    | "source"
    | "track"
    | "wbr" => true
    _ => false
  }
}

///|
/// is_attr reports whether n belongs in a start tag rather than in content.
fn is_attr(n : Node) -> Bool {
  n is (Attr(_) | BoolAttr(_))
}

///|
/// write_html writes n to sb as HTML5.
fn write_html(sb : StringBuilder, n : Node) -> Unit {
  match n {
    Text(s) => escape_to(sb, s)
    Raw(s) => sb.write_string(s)
    Attr(AttrName(k), v) => {
      sb.write_string(" \{k}=\"")
      escape_to(sb, v)
      sb.write_char('"')
    }
    BoolAttr(AttrName(k)) => sb.write_string(" \{k}")
    Element(name, children) => {
      sb.write_string("<\{name.0}")
      for c in children {
        if is_attr(c) {
          write_html(sb, c)
        }
      }
      sb.write_char('>')
      if is_void(name) {
        return
      }
      for c in children {
        if !is_attr(c) {
          write_html(sb, c)
        }
      }
      sb.write_string("</\{name.0}>")
    }
  }
}

///|
/// render_html returns n as HTML5. Text and attribute values are escaped;
/// Raw is written as is.
pub fn render_html(n : Node) -> String {
  let sb = StringBuilder()
  write_html(sb, n)
  sb.to_string()
}

///|
/// is_block reports whether render_plain puts elements named name on their
/// own lines.
fn is_block(name : Tag) -> Bool {
  match name.0 {
    "address"
    | "article"
    | "aside"
    | "blockquote"
    | "body"
    | "br"
    | "dd"
    | "details"
    | "div"
    | "dl"
    | "dt"
    | "figcaption"
    | "figure"
    | "footer"
    | "form"
    | "h1"
    | "h2"
    | "h3"
    | "h4"
    | "h5"
    | "h6"
    | "head"
    | "header"
    | "hgroup"
    | "hr"
    | "html"
    | "li"
    | "main"
    | "nav"
    | "ol"
    | "p"
    | "pre"
    | "section"
    | "summary"
    | "table"
    | "title"
    | "tr"
    | "ul" => true
    _ => false
  }
}

///|
/// LineWriter remembers whether the output is empty or ends a line, so
/// that break_line never emits a blank line or a leading newline.
priv struct LineWriter {
  sb : StringBuilder
  mut at_line_start : Bool
}

///|
fn LineWriter::write(self : LineWriter, s : String) -> Unit {
  if s != "" {
    self.sb.write_string(s)
    self.at_line_start = s.has_suffix("\n")
  }
}

///|
fn LineWriter::break_line(self : LineWriter) -> Unit {
  if !self.at_line_start {
    self.write("\n")
  }
}

///|
/// write_plain writes the text content of n to w.
fn write_plain(w : LineWriter, n : Node) -> Unit {
  match n {
    Text(s) => w.write(s)
    Raw(_) | Attr(_) | BoolAttr(_) => ()
    Element(name, children) => {
      let block = is_block(name)
      if block {
        w.break_line()
      }
      for c in children {
        write_plain(w, c)
      }
      if block {
        w.break_line()
      }
    }
  }
}

///|
/// render_plain returns only the text content of n, dropping tags,
/// attributes, and raw markup. Text is not escaped. Block-level elements
/// (paragraphs, headings, list items, ...) start and end on their own
/// line, so the output reads like the page. Useful for debugging and for
/// tests that check what a page says.
pub fn render_plain(n : Node) -> String {
  let w = LineWriter::{ sb: StringBuilder(), at_line_start: true, }
  write_plain(w, n)
  w.sb.to_string()
}
