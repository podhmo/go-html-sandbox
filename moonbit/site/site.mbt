///|
/// write_escaped writes s to sb with the characters special in HTML
/// replaced by entities.
fn write_escaped(sb : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '<' => sb <+ "&lt;"
      '>' => sb <+ "&gt;"
      '&' => sb <+ "&amp;"
      '"' => sb <+ "&quot;"
      '\'' => sb <+ "&#39;"
      _ => sb.write_char(c)
    }
  }
}

///|
/// page writes a full HTML document with title and body to sb.
fn page(
  sb : StringBuilder,
  title : String,
  body : (StringBuilder) -> Unit,
) -> Unit {
  sb <+
    "<!doctype html>\n<html lang=\"ja\"><head><meta charset=\"utf-8\"><title>"
  write_escaped(sb, title)
  sb <+ "</title></head><body>"
  body(sb)
  sb <+ "</body></html>"
}

///|
/// Response is what the site answers to a request.
pub(all) struct Response {
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
  let sb = StringBuilder()
  match path {
    "/" => {
      page(sb, "blog", sb => sb <+ "<h1>blog</h1><p>Rendered with MoonBit.</p>")
      Response::html(200, body=sb.to_string())
    }
    _ => {
      page(sb, "Not found | blog", sb => {
        sb <+ "<h1>Not found</h1><p>No page at <code>"
        write_escaped(sb, path)
        sb <+ "</code>.</p>"
      })
      Response::html(404, body=sb.to_string())
    }
  }
}
