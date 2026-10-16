// The first Wasm: Markdown to the tree of tinymarkdown, as JSON text. JSON
// is what crosses between the two Wasm modules (and over postMessage), as
// MoonBit's values cannot be shared between modules built apart.

///|
/// parse reads md and writes its blocks as JSON, with the inline Markdown
/// already split into text, code spans and links.
pub fn parse(md : String) -> String {
  Json::array(@tinymarkdown.parse(md).children.map(block)).stringify()
}

///|
fn block(b : @tinymarkdown.Block) -> Json {
  match b {
    Section(level~, title~, children~) =>
      {
        "t": "section",
        "level": Json(level),
        "title": inlines(title),
        "children": Json::array(children.map(block)),
      }
    Paragraph(text) => { "t": "p", "text": inlines(text) }
    List(items) => { "t": "list", "items": Json::array(items.map(item)) }
    Quote(children) =>
      { "t": "quote", "children": Json::array(children.map(block)) }
    Table(header~, rows~) =>
      {
        "t": "table",
        "header": Json::array(header.map(inlines)),
        "rows": Json::array(rows.map(r => Json::array(r.map(inlines)))),
      }
    CodeBlock(code) => { "t": "code", "text": Json(code) }
  }
}

///|
fn item(it : @tinymarkdown.Item) -> Json {
  { "text": inlines(it.text), "children": Json::array(it.children.map(item)) }
}

///|
fn inlines(s : String) -> Json {
  Json::array(@tinymarkdown.inlines(s).map(inline))
}

///|
fn inline(i : @tinymarkdown.Inline) -> Json {
  match i {
    Text(s) => { "t": "text", "s": Json(s) }
    Code(s) => { "t": "code", "s": Json(s) }
    Link(children~, url~) =>
      {
        "t": "link",
        "url": Json(url),
        "children": Json::array(children.map(inline)),
      }
  }
}
