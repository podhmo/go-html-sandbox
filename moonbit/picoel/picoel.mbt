// picoel builds pages styled by pico.css v2, on top of el: a port of
// go/pkg/picoel, keeping the part the blog's pages use. Script is left
// out, since it serves only the Go blog's live reload.
//
// Following pico's approach, there are no custom classes: layout and
// decoration come from semantic elements (article, nav, hgroup, ...) and
// the classes pico ships with (container). Every helper returns an
// @el.Node, rendered by @el.render_html like any other tree.

///|
/// STYLESHEET_URL is pico.css v2 on a CDN.
pub const STYLESHEET_URL = "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css"

///|
/// document is the <html> element in pico's dark theme: the head carries
/// the charset, viewport, color scheme, and the pico stylesheet, followed
/// by head. The doctype is the caller's job.
pub fn document(
  lang : String,
  head~ : Array[@el.Node],
  body : Array[@el.Node],
) -> @el.Node {
  let h = [
    @el.el(@el.meta, [@el.Attr(@el.charset, "utf-8")]),
    meta_name("viewport", "width=device-width, initial-scale=1"),
    meta_name("color-scheme", "dark"),
    stylesheet(STYLESHEET_URL),
    ..head,
  ]
  @el.el(@el.html, [
    @el.Attr(@el.lang, lang),
    @el.Attr(@el.AttrName("data-theme"), "dark"),
    @el.el(@el.head, h),
    @el.el(@el.body, body),
  ])
}

///|
/// title is the document title.
pub fn title(s : String) -> @el.Node {
  @el.el(@el.title, [@el.Text(s)])
}

///|
/// meta_name is <meta name content>.
pub fn meta_name(name : String, content : String) -> @el.Node {
  @el.el(@el.meta, [@el.Attr(@el.name, name), @el.Attr(@el.content, content)])
}

///|
/// meta_property is <meta property content>, as used by Open Graph.
pub fn meta_property(property : String, content : String) -> @el.Node {
  @el.el(@el.meta, [
    @el.Attr(@el.property, property),
    @el.Attr(@el.content, content),
  ])
}

///|
/// stylesheet links the stylesheet at href. document already links pico;
/// use this for the few rules pico cannot express, placed after it.
pub fn stylesheet(href : String) -> @el.Node {
  @el.el(@el.link, [@el.Attr(@el.rel, "stylesheet"), @el.Attr(@el.href, href)])
}

///|
/// icon links the favicon at href with the given MIME type.
pub fn icon(href : String, mime_type : String) -> @el.Node {
  @el.el(@el.link, [
    @el.Attr(@el.rel, "icon"),
    @el.Attr(@el.href, href),
    @el.Attr(@el.type_attr, mime_type),
  ])
}

///|
/// container is pico's centered, responsive width.
fn container() -> @el.Node {
  @el.Attr(@el.class, "container")
}

///|
/// header is the page header, centered by .container.
pub fn header(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.header, [container(), ..children])
}

///|
/// main_ is the page body, centered by .container. The underscore keeps it
/// apart from `fn main`, which only a main package may define.
pub fn main_(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.main, [container(), ..children])
}

///|
/// footer is the page footer, centered by .container.
pub fn footer(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.footer, [container(), ..children])
}

///|
/// list_items wraps each item in a list item.
fn list_items(items : Array[@el.Node]) -> Array[@el.Node] {
  [
    for it in items => @el.el(@el.li, [it])
  ]
}

///|
/// nav is a navigation bar. Each item becomes a list item; pico lays them
/// out in a row.
pub fn nav(items : Array[@el.Node]) -> @el.Node {
  @el.el(@el.nav, [@el.el(@el.ul, list_items(items))])
}

///|
/// spread puts start at the leading edge and end at the trailing edge of
/// one row, using pico's nav layout: each side is a list and the lists are
/// pushed apart.
pub fn spread(start : Array[@el.Node], end : Array[@el.Node]) -> @el.Node {
  @el.el(@el.nav, [
    @el.el(@el.ul, list_items(start)),
    @el.el(@el.ul, list_items(end)),
  ])
}

///|
/// article is a card.
pub fn article(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.article, children)
}

///|
/// inner_header is a header without .container, for use inside main or an
/// article rather than at the top of the page. Inside an article pico
/// draws it as a band.
pub fn inner_header(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.header, children)
}

///|
/// hgroup groups a heading with lines that pico shows in a muted color.
pub fn hgroup(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.hgroup, children)
}

///|
/// section is a section of a document.
pub fn section(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.section, children)
}

///|
/// h1 is a level 1 heading.
pub fn h1(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.h1, children)
}

///|
/// h2 is a level 2 heading.
pub fn h2(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.h2, children)
}

///|
/// h3 is a level 3 heading.
pub fn h3(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.h3, children)
}

///|
/// h4 is a level 4 heading.
pub fn h4(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.h4, children)
}

///|
/// h5 is a level 5 heading.
pub fn h5(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.h5, children)
}

///|
/// p is a paragraph.
pub fn p(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.p, children)
}

///|
/// list is an unordered list of li items.
pub fn list(items : Array[@el.Node]) -> @el.Node {
  @el.el(@el.ul, items)
}

///|
/// li is a list item.
pub fn li(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.li, children)
}

///|
/// blockquote is a quotation; pico draws a bar on its leading edge.
pub fn blockquote(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.blockquote, children)
}

///|
/// table is a table with a header row and body rows; each cell is a list
/// of nodes. It is wrapped in pico's overflow-auto div so that a wide table
/// scrolls sideways instead of widening the page on small screens.
pub fn table(
  header : Array[Array[@el.Node]],
  rows : Array[Array[Array[@el.Node]]],
) -> @el.Node {
  fn row(tag : @el.Tag, cells : Array[Array[@el.Node]]) -> @el.Node {
    @el.el(@el.tr, [ for c in cells => @el.el(tag, c) ])
  }

  let parts = [@el.el(@el.thead, [row(@el.th, header)])]
  if !rows.is_empty() {
    parts.push(@el.el(@el.tbody, [ for r in rows => row(@el.td, r) ]))
  }
  @el.el(@el.div, [
    @el.Attr(@el.class, "overflow-auto"),
    @el.el(@el.table, parts),
  ])
}

///|
/// pre is preformatted text such as a code block.
pub fn pre(text : String) -> @el.Node {
  @el.el(@el.pre, [@el.Text(text)])
}

///|
/// code is a fragment of code inside text.
pub fn code(text : String) -> @el.Node {
  @el.el(@el.code, [@el.Text(text)])
}

///|
/// a is a link to href.
pub fn a(href : String, children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.a, [@el.Attr(@el.href, href), ..children])
}

///|
/// download_link is a link that downloads href as filename, in pico's
/// muted secondary color.
pub fn download_link(
  href : String,
  filename : String,
  children : Array[@el.Node],
) -> @el.Node {
  @el.el(
    @el.a,
    [
      @el.Attr(@el.href, href),
      @el.Attr(@el.download, filename),
      @el.Attr(@el.class, "secondary"),
      ..children,
    ],
  )
}

///|
/// strong is strong importance, e.g. the site name in a nav.
pub fn strong(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.strong, children)
}

///|
/// small is side comments and fine print.
pub fn small(children : Array[@el.Node]) -> @el.Node {
  @el.el(@el.small, children)
}

///|
/// date is a <time> showing day, a date written as YYYY-MM-DD. MoonBit's
/// core has no time type, and the blog takes its dates from file names in
/// that form, so the Go version's time.Time becomes the string itself.
pub fn date(day : String) -> @el.Node {
  @el.el(@el.time, [@el.Attr(@el.datetime, day), @el.Text(day)])
}

///|
/// text is escaped text.
pub fn text(s : String) -> @el.Node {
  @el.Text(s)
}
