///|
/// page returns a full HTML document with title and body, as HTML.
fn page(title~ : String, body~ : Array[@el.Node]) -> String {
  let doc = @el.el(@el.html, [
    @el.Attr(@el.lang, "ja"),
    @el.el(@el.head, [
      @el.el(@el.meta, [@el.Attr(@el.charset, "utf-8")]),
      @el.el(@el.title, [@el.Text(title)]),
    ]),
    @el.el(@el.body, body),
  ])
  "<!doctype html>\n\{@el.render_html(doc)}"
}

///|
/// Response is what the site answers to a request.
pub struct Response {
  status : Int32
  headers : Array[(String, String)]
  body : String
}

///|
/// Response::html wraps an HTML page with status.
fn Response::html(status : Int32, body~ : String) -> Response {
  { status, headers: [("content-type", "text/html; charset=utf-8")], body, }
}

///|
/// render answers the request for path: the top page for "/", and a 404
/// page saying nothing is there for any other path.
pub fn render(path : String) -> Response {
  match path {
    "/" =>
      Response::html(
        200,
        body=page(title="blog", body=[
          @el.el(@el.h1, [@el.Text("blog")]),
          @el.el(@el.p, [@el.Text("Rendered with MoonBit.")]),
        ]),
      )
    _ =>
      Response::html(
        404,
        body=page(title="Not found | blog", body=[
          @el.el(@el.h1, [@el.Text("Not found")]),
          @el.el(@el.p, [
            @el.Text("No page at "),
            @el.el(@el.code, [@el.Text(path)]),
            @el.Text("."),
          ]),
        ]),
      )
  }
}
