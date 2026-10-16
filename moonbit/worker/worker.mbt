///|
/// base_url is the public origin the site was loaded with.
let base_url : Ref[String] = Ref("")

///|
/// site is the content being served, loaded on the first request (and
/// again if BASE_URL changes), or why it could not be.
let site : Ref[Result[@site.Site, String]?] = Ref(None)

///|
/// load returns the site for base, loading it on first use.
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
/// answer parses a request, "BASE_URL\nmethod\nquery\npath" (the path
/// last, since only it may hold a newline), and returns the response as
/// its head, "status\nname\tvalue\n...\n\n", and its body. If the
/// embedded content cannot be loaded, every request gets a 500 saying why.
fn answer(req : String) -> (String, String) {
  let fields = []
  let mut start = 0
  for i in 0..<req.length() {
    if fields.length() == 3 {
      break
    }
    if req.code_unit_at(i) == '\n' {
      fields.push(req.unsafe_substring(start~, end=i))
      start = i + 1
    }
  }
  guard fields is [base, verb, query] else {
    return ("400\ncontent-type\ttext/plain; charset=utf-8\n\n", "Bad request\n")
  }
  let path = req.unsafe_substring(start~, end=req.length())
  let res = match load(base) {
    Ok(s) => s.render(path, query~, verb~)
    Err(msg) => @site.Response::text(500, "\{msg}\n")
  }
  let head = StringBuilder()
  head.write_string("\{res.status}\n")
  for (name, value) in res.headers {
    head.write_string("\{name}\t\{value}\n")
  }
  head.write_char('\n')
  (head.to_string(), res.body)
}

///|
/// serve answers the request the host wrote at address 0 of the memory,
/// n bytes of UTF-8 (see answer), and writes the response over it in
/// UTF-8, the head and then the body, returning its length in bytes.
/// Strings cross this way, not as JS strings, since Workers compiles the
/// Wasm without the JS string builtins; see
/// docs/sketch/ja/moonbit-workers-adapter.md.
pub fn serve(n : Int32) -> Int32 {
  let (head, body) = answer(read(n))
  write(write(0, head), body)
}
