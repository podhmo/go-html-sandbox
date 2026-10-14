///|
/// put sends one UTF-16 code unit of the response body to the host. The
/// Wasm passes strings this way since Workers cannot compile it with the JS
/// string builtins; see docs/sketch/ja/moonbit-workers-wasm.md.
fn put(code : Int) = "host" "put"

///|
let path : StringBuilder = StringBuilder()

///|
/// path_push appends one UTF-16 code unit of the request path.
pub fn path_push(code : Int) -> Unit {
  path.write_char(code.unsafe_to_char())
}

///|
/// serve renders the page for the pushed path, sends it through put, and
/// clears the path for the next request.
pub fn serve() -> Unit {
  let p = path.to_string()
  path.reset()
  let html = @site.render(p)
  for i in 0..<html.length() {
    put(html.code_unit_at(i).to_int())
  }
}
