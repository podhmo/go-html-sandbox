///|
/// put appends one UTF-16 code unit to the host's buffer. The Wasm passes
/// strings this way since Workers cannot compile it with the JS string
/// builtins; see docs/sketch/ja/moonbit-workers-wasm.md.
fn put(code : Int32) = "host" "put"

///|
/// status sets the status code of the response.
fn status(code : Int32) = "host" "status"

///|
/// header_name takes the host's buffer as the name of the next header.
fn header_name() = "host" "header_name"

///|
/// header_value takes the host's buffer as the value of the header named
/// last.
fn header_value() = "host" "header_value"

///|
/// put8 appends eight UTF-16 code units, two per argument (the first in
/// the low 16 bits).
fn put8(a : Int32, b : Int32, c : Int32, d : Int32) = "host" "put8"

///|
fn put_string(s : String) -> Unit {
  let n = s.length()
  let mut i = 0
  while i + 8 <= n {
    let u = fn(k) { s.code_unit_at(i + k).to_int() }
    put8(u(0) | (u(1) << 16), u(2) | (u(3) << 16), u(4) | (u(5) << 16), u(6) | (u(7) << 16))
    i += 8
  }
  for j in i..<n {
    put(s.code_unit_at(j).to_int())
  }
}

///|
let path : StringBuilder = StringBuilder()

///|
/// path_push appends one UTF-16 code unit of the request path, or of the
/// base URL before set_base_url, or of the query before set_query.
pub fn path_push(code : Int32) -> Unit {
  path.write_char(code.unsafe_to_char())
}

///|
/// base_url is the public origin set by set_base_url.
let base_url : Ref[String] = Ref("")

///|
/// site is the content being served, loaded on the first request, or why
/// it could not be.
let site : Ref[Result[@site.Site, String]?] = Ref(None)

///|
/// set_base_url takes what path_push pushed as the public origin for the
/// OGP tags (BASE_URL in wrangler.jsonc). The host calls it once, before
/// the first serve.
pub fn set_base_url() -> Unit {
  base_url.val = path.to_string()
  path.reset()
  site.val = None
}

///|
/// query is the raw query string of the next request, set by set_query.
let query : Ref[String] = Ref("")

///|
/// set_query takes what path_push pushed as the raw query string (without
/// "?") of the next request. The host calls it before pushing the path,
/// when the request has a query; serve clears it.
pub fn set_query() -> Unit {
  query.val = path.to_string()
  path.reset()
}

///|
/// load returns the site, loading it on first use.
fn load() -> Result[@site.Site, String] {
  match site.val {
    Some(s) => s
    None => {
      let s = Ok(@site.Site::embedded(base_url=base_url.val)) catch {
        e => Err("\{e}")
      }
      site.val = Some(s)
      s
    }
  }
}

///|
/// serve answers the pushed path, and clears it for the next request. It
/// sends the status, then each header as a name and a value, then the
/// body, which is what the host's buffer holds when serve returns. If the
/// embedded content cannot be loaded, every request gets a 500 saying why.
pub fn serve() -> Unit {
  let p = path.to_string()
  path.reset()
  let q = query.val
  query.val = ""
  let res = match load() {
    Ok(s) => s.render(p, query=q)
    Err(msg) => @http.Response::text(500, "\{msg}\n")
  }
  status(res.status)
  for (name, value) in res.headers {
    put_string(name)
    header_name()
    put_string(value)
    header_value()
  }
  put_string(res.body.text())
}
