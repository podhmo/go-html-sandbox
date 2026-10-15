///|
/// write_escaped writes s escaped the way Go's html.EscapeString does, so
/// that pages match the Go blog byte for byte.
fn StringBuilder::write_escaped(self : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '<' => self <+ "&lt;"
      '>' => self <+ "&gt;"
      '&' => self <+ "&amp;"
      '\'' => self <+ "&#39;"
      '"' => self <+ "&#34;"
      _ => self.write_char(c)
    }
  }
}

///|
/// is_void reports whether elements named self have no content and no end
/// tag.
fn Tag::is_void(self : Tag) -> Bool {
  match self.0 {
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
/// is_attr reports whether self belongs in a start tag rather than in
/// content.
fn Node::is_attr(self : Node) -> Bool {
  self is (Attr(_) | BoolAttr(_))
}

///|
/// write_html writes self to sb as HTML5.
fn Node::write_html(self : Node, sb : StringBuilder) -> Unit {
  match self {
    Text(s) => sb.write_escaped(s)
    Raw(s) => sb.write_string(s)
    Attr(AttrName(k), v) => {
      sb <+ " \{k}=\""
      sb.write_escaped(v)
      sb.write_char('"')
    }
    BoolAttr(AttrName(k)) => sb <+ " \{k}"
    Element(name, children) => {
      sb <+ "<\{name.0}"
      for c in children {
        if c.is_attr() {
          c.write_html(sb)
        }
      }
      sb.write_char('>')
      if name.is_void() {
        return
      }
      for c in children {
        if !c.is_attr() {
          c.write_html(sb)
        }
      }
      sb <+ "</\{name.0}>"
    }
  }
}

///|
/// render_html returns n as HTML5. Text and attribute values are escaped;
/// Raw is written as is.
pub fn render_html(n : Node) -> String {
  let sb = StringBuilder()
  n.write_html(sb)
  sb.to_string()
}

///|
/// is_block reports whether render_plain puts elements named self on their
/// own lines.
fn Tag::is_block(self : Tag) -> Bool {
  match self.0 {
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
/// write_plain writes the text content of self to w.
fn Node::write_plain(self : Node, w : LineWriter) -> Unit {
  match self {
    Text(s) => w.write(s)
    Raw(_) | Attr(_) | BoolAttr(_) => ()
    Element(name, children) => {
      let block = name.is_block()
      if block {
        w.break_line()
      }
      for c in children {
        c.write_plain(w)
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
  n.write_plain(w)
  w.sb.to_string()
}
