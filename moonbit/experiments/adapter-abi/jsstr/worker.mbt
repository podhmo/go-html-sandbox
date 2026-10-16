///|
let base_url : Ref[String] = Ref("")

///|
let site : Ref[Result[@site.Site, String]?] = Ref(None)

///|
fn load(base : String) -> Result[@site.Site, String] {
  match site.val {
    Some(s) if base == base_url.val => s
    _ => {
      base_url.val = base
      let s = Ok(@site.Site::embedded(base_url=base)) catch { e => Err("\{e}") }
      site.val = Some(s)
      s
    }
  }
}

///|
/// serve answers a request with JS strings in and out, returning the
/// response as "status\nname\tvalue\n...\n\n" followed by the body.
pub fn serve(
  base : String,
  verb : String,
  path : String,
  query : String,
) -> String {
  let res = match load(base) {
    Ok(s) => s.render(path, query~, verb~)
    Err(msg) => @http.Response::text(500, "\{msg}\n")
  }
  let head = StringBuilder()
  head.write_string("\{res.status}\n")
  for (name, value) in res.headers {
    head.write_string("\{name}\t\{value}\n")
  }
  head.write_char('\n')
  head.to_string() + res.body.text()
}
