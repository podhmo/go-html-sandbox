// The pages: a port of the Go blog's views.go.

///|
const SITE_NAME = "blog"

///|
const SITE_DESCRIPTION = "Notes rendered with the Go standard library only."

///|
/// PageMeta describes a page for <head>. title and description may hold
/// inline Markdown, which layout reduces to plain text.
priv struct PageMeta {
  title : String // page title without the site name; empty for the top page
  description : String
  // url is the absolute URL of the page. OGP tags are written only when
  // it is set, so error pages have none.
  url : String
  type_ : String // OGP type: "website" or "article"
}

///|
/// site_css_path carries a hash of site.css, so browsers may cache it for
/// long and still pick up a new version right after a deploy.
fn site_css_path() -> String {
  "/site.css?v=\{@assets.site_css_version}"
}

///|
/// layout is the frame shared by every page. The doctype is written by
/// Response::page.
fn layout(meta : PageMeta, body : Array[@el.Node]) -> @el.Node {
  let title = plain_text(meta.title)
  let description = plain_text(meta.description)
  let head = [
    @picoel.title(document_title(title)),
    @picoel.meta_name("description", content=description),
    ..ogp({ ..meta, title, description, }),
    @picoel.stylesheet(site_css_path()),
    @picoel.icon("/favicon.svg", mime_type="image/svg+xml"),
  ]
  @picoel.document("ja", head~, [
    @picoel.header([
      @picoel.nav([
        @picoel.a("/", [@picoel.strong([@picoel.text(SITE_NAME)])]),
        @picoel.a("/docs/", [@picoel.text("docs")]),
      ]),
    ]),
    @picoel.main_(body),
    @picoel.footer([
      @picoel.small([@picoel.text("Rendered with the Go standard library.")]),
    ]),
  ])
}

///|
/// document_title is the <title> text: the page title followed by the site
/// name.
fn document_title(title : String) -> String {
  if title == "" {
    SITE_NAME
  } else {
    "\{title} - \{SITE_NAME}"
  }
}

///|
/// ogp returns Open Graph <meta> tags, or none when meta has no URL.
fn ogp(meta : PageMeta) -> Array[@el.Node] {
  if meta.url == "" {
    return []
  }
  [
    @picoel.meta_property(
      "og:title",
      content=if meta.title == "" { SITE_NAME } else { meta.title },
    ),
    @picoel.meta_property("og:type", content=meta.type_),
    @picoel.meta_property("og:url", content=meta.url),
    @picoel.meta_property("og:description", content=meta.description),
    @picoel.meta_property("og:site_name", content=SITE_NAME),
  ]
}

///|
/// post_list shows each post as a card: the title links to the post and
/// the date below it is muted by hgroup.
fn Site::post_list(self : Site) -> @el.Node {
  let body = [@picoel.h1([@picoel.text("Posts")])]
  for p in self.posts {
    body.push(
      @picoel.article([
        @picoel.hgroup([
          @picoel.h2([@picoel.a(p.page_path(), linked_title(p.title))]),
          @picoel.p([@picoel.date(p.date)]),
        ]),
      ]),
    )
  }
  layout(
    {
      title: "",
      description: SITE_DESCRIPTION,
      url: "\{self.base_url}/",
      type_: "website",
    },
    body,
  )
}

///|
fn Site::post_page(self : Site, p : Post) -> @el.Node {
  let link = self.linker(p.source())
  let body = []
  if first_title(p.doc) is None {
    // The title came from front matter only, so the body has no heading.
    body.push(@picoel.h1(render_inlines(@tinymarkdown.inlines(p.title), link)))
  }
  body.push_iter(render_blocks(p.doc.children, link).iter())
  let meta = PageMeta::{
    title: p.title,
    description: p.description,
    url: "\{self.base_url}\{p.page_path()}",
    type_: "article",
  }
  layout(meta, [
    page_header(@picoel.date(p.date), href=p.markdown_path(), filename=p.file),
    @picoel.article(body),
  ])
}

///|
/// doc_list links to every repository document, showing its file path
/// below the title.
fn Site::doc_list(self : Site) -> @el.Node {
  let body = [@picoel.h1([@picoel.text("Docs")])]
  for d in self.docs {
    body.push(
      @picoel.article([
        @picoel.hgroup([
          @picoel.h2([@picoel.a(d.page_path(), linked_title(d.title))]),
          @picoel.p([@picoel.text(d.source)]),
        ]),
      ]),
    )
  }
  let meta = PageMeta::{
    title: "Docs",
    description: "Documents of this repository.",
    url: "\{self.base_url}/docs/",
    type_: "website",
  }
  layout(meta, body)
}

///|
fn Site::doc_page(self : Site, d : Doc) -> @el.Node {
  let link = self.linker(d.source)
  let body = []
  if first_title(d.doc) is None {
    body.push(@picoel.h1(render_inlines(@tinymarkdown.inlines(d.title), link)))
  }
  body.push_iter(render_blocks(d.doc.children, link).iter())
  let meta = PageMeta::{
    title: d.title,
    description: d.description,
    url: "\{self.base_url}\{d.page_path()}",
    type_: "article",
  }
  layout(meta, [
    page_header(
      @picoel.small([@picoel.text(d.source)]),
      href=d.markdown_path(),
      filename=base(d.source),
    ),
    @picoel.article(body),
  ])
}

///|
fn Post::page_path(self : Post) -> String {
  "/posts/\{self.slug}"
}

///|
/// Post::markdown_path is where the post's Markdown source is served.
fn Post::markdown_path(self : Post) -> String {
  "\{self.page_path()}.md"
}

///|
fn Doc::page_path(self : Doc) -> String {
  "/docs/\{self.path}"
}

///|
/// Doc::markdown_path is where the document's Markdown source is served.
fn Doc::markdown_path(self : Doc) -> String {
  "\{self.page_path()}.md"
}

///|
/// page_header is the row above the article: info on the left and, on the
/// right, a small link that downloads the page's Markdown source. It sits
/// in main rather than in the article, where pico would pad it into a
/// band.
fn page_header(info : @el.Node, href~ : String, filename~ : String) -> @el.Node {
  let download = @picoel.small([
    @picoel.download_link(href, filename~, [@picoel.text("Download .md")]),
  ])
  @picoel.inner_header([@picoel.spread([info], end=[download])])
}

///|
/// status_text is Go's http.StatusText for the statuses the site sends.
fn status_text(status : Int32) -> String {
  match status {
    404 => "Not Found"
    500 => "Internal Server Error"
    _ => ""
  }
}

///|
fn error_page(status : Int32, message : String) -> @el.Node {
  let title = "\{status} \{status_text(status)}"
  layout({ title, description: message, url: "", type_: "", }, [
    @picoel.h1([@picoel.text(title)]),
    @picoel.p([@picoel.text(message)]),
    @picoel.p([@picoel.a("/", [@picoel.text("Back to all posts")])]),
  ])
}

///|
fn heading(level : Int32, children : Array[@el.Node]) -> @el.Node {
  match level {
    1 => @picoel.h1(children)
    2 => @picoel.h2(children)
    3 => @picoel.h3(children)
    4 => @picoel.h4(children)
    _ => @picoel.h5(children)
  }
}

///|
/// render_blocks converts the Markdown tree into nodes. Every piece of text
/// goes through @picoel.text, so HTML in posts is escaped. link resolves
/// the URLs of links.
fn render_blocks(
  bs : Array[@tinymarkdown.Block],
  link : Linker,
) -> Array[@el.Node] {
  let inlines = (s : String) => render_inlines(@tinymarkdown.inlines(s), link)
  bs.map(b => {
    match b {
      Section(level~, title~, children~) =>
        @picoel.section(
          [heading(level, inlines(title)), ..render_blocks(children, link)],
        )
      Paragraph(text) => @picoel.p(inlines(text))
      List(items) =>
        @picoel.list([ for it in items => @picoel.li(inlines(it)) ])
      Quote(children) => @picoel.blockquote(render_blocks(children, link))
      Table(header~, rows~) => {
        let cells = (row : Array[String]) => [ for c in row => inlines(c) ]
        @picoel.table(cells(header), [ for r in rows => cells(r) ])
      }
      CodeBlock(code) => @picoel.pre(code)
    }
  })
}

///|
/// linked_title renders a title written in Markdown inside the link to its
/// page. Links in the title show only their text, as links cannot nest.
fn linked_title(title : String) -> Array[@el.Node] {
  render_inlines(@tinymarkdown.inlines(title), (_ : String) => None)
}

///|
/// plain_text drops the markup of inline Markdown: code spans and links
/// keep only their text. It is for places that hold no HTML, such as
/// <title>.
fn plain_text(s : String) -> String {
  let sb = StringBuilder()
  fn walk(ins : Array[@tinymarkdown.Inline]) {
    for i in ins {
      match i {
        Text(t) | Code(t) => sb.write_string(t)
        Link(children~, ..) => walk(children)
      }
    }
  }

  walk(@tinymarkdown.inlines(s))
  sb.to_string()
}

///|
/// render_inlines turns code spans into <code> and links into <a>; the
/// rest is text. A link whose URL link rejects shows only its text.
fn render_inlines(
  ins : Array[@tinymarkdown.Inline],
  link : Linker,
) -> Array[@el.Node] {
  let out = []
  for i in ins {
    match i {
      Text(t) => out.push(@picoel.text(t))
      Code(t) => out.push(@picoel.code(t))
      Link(children~, url~) => {
        let children = render_inlines(children, link)
        match link(url) {
          Some(href) => out.push(@picoel.a(href, children))
          None => out.push_iter(children.iter())
        }
      }
    }
  }
  out
}
