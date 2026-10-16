// render for the browser: Markdown to an HTML fragment, through
// tinymarkdown, picoel and el. It is a smaller copy of the blog's
// render_blocks and render_inlines (../../../examples/blog/site/views.mbt),
// which are private: headings are only h2 and h3, and links keep any URL.

///|
/// render turns Markdown into an HTML fragment, for the browser to call.
pub fn render(md : String) -> String {
  let doc = @tinymarkdown.parse(md)
  @el.render_html(@picoel.article(blocks(doc.children)))
}

///|
fn blocks(bs : Array[@tinymarkdown.Block]) -> Array[@el.Node] {
  bs.map(b => {
    match b {
      Section(level~, title~, children~) => {
        let t = inlines(title)
        let h = if level <= 1 { @picoel.h2(t) } else { @picoel.h3(t) }
        @picoel.section([h, ..blocks(children)])
      }
      Paragraph(text) => @picoel.p(inlines(text))
      List(items) => @picoel.list(items.map(it => @picoel.li(inlines(it.text))))
      Quote(children) => @picoel.blockquote(blocks(children))
      Table(header~, rows~) => {
        let cells = (row : Array[String]) => [ for c in row => inlines(c) ]
        @picoel.table(cells(header), [ for r in rows => cells(r) ])
      }
      CodeBlock(code) => @picoel.pre(code)
    }
  })
}

///|
fn inlines(s : String) -> Array[@el.Node] {
  @tinymarkdown.inlines(s).map(i => {
    match i {
      Text(t) => @picoel.text(t)
      Code(t) => @picoel.code(t)
      Link(children~, url~) =>
        @picoel.a(
          url,
          children.map(c => {
            match c {
              Text(t) | Code(t) => @picoel.text(t)
              Link(..) => @picoel.text("")
            }
          }),
        )
    }
  })
}
