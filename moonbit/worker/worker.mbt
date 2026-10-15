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
fn put_string(s : String) -> Unit {
  for i in 0..<s.length() {
    put(s.code_unit_at(i).to_int())
  }
}

///|
let path : StringBuilder = StringBuilder()

///|
/// path_push appends one UTF-16 code unit of the request path.
pub fn path_push(code : Int32) -> Unit {
  path.write_char(code.unsafe_to_char())
}

///|
/// serve answers the pushed path, and clears it for the next request. It
/// sends the status, then each header as a name and a value, then the
/// body, which is what the host's buffer holds when serve returns.
pub fn serve() -> Unit {
  let p = path.to_string()
  path.reset()
  let res = @site.render(p)
  status(res.status)
  for h in res.headers {
    put_string(h.0)
    header_name()
    put_string(h.1)
    header_value()
  }
  put_string(res.body)
}
