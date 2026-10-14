///|
/// write_escaped writes s to sb with the characters special in HTML
/// replaced by entities.
fn write_escaped(sb : StringBuilder, s : String) -> Unit {
  for c in s {
    match c {
      '<' => sb.write_string("&lt;")
      '>' => sb.write_string("&gt;")
      '&' => sb.write_string("&amp;")
      '"' => sb.write_string("&quot;")
      '\'' => sb.write_string("&#39;")
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
  sb.write_string(
    "<!doctype html>\n<html lang=\"ja\"><head><meta charset=\"utf-8\"><title>",
  )
  write_escaped(sb, title)
  sb.write_string("</title></head><body>")
  body(sb)
  sb.write_string("</body></html>")
}

///|
/// Response is what the site answers to a request.
pub(all) struct Response {
  status : Int
  headers : Array[(String, String)]
  body : String
}

///|
/// html_response wraps an HTML page with status.
fn html_response(status : Int, body : String) -> Response {
  { status, headers: [("content-type", "text/html; charset=utf-8")], body, }
}

///|
/// render answers the request for path: the top page for "/", and a 404
/// page saying nothing is there for any other path.
pub fn render(path : String) -> Response {
  let sb = StringBuilder()
  match path {
    "/" => {
      page(sb, "blog", fn(sb) {
        sb.write_string("<h1>blog</h1><p>Rendered with MoonBit.</p>")
      })
      html_response(200, sb.to_string())
    }
    _ => {
      page(sb, "Not found | blog", fn(sb) {
        sb.write_string("<h1>Not found</h1><p>No page at <code>")
        write_escaped(sb, path)
        sb.write_string("</code>.</p>")
      })
      html_response(404, sb.to_string())
    }
  }
}
