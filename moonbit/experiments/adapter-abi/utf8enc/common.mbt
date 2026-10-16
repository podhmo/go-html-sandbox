///|
extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) (i32.load8_u (local.get 0)))

///|
extern "wasm" fn store8(addr : Int, v : Int) =
  #|(func (param i32) (param i32) (i32.store8 (local.get 0) (local.get 1)))

///|
extern "wasm" fn load16(addr : Int) -> Int =
  #|(func (param i32) (result i32) (i32.load16_u (local.get 0)))

///|
extern "wasm" fn store16(addr : Int, v : Int) =
  #|(func (param i32) (param i32) (i32.store16 (local.get 0) (local.get 1)))

///|
extern "wasm" fn memory_size() -> Int =
  #|(func (result i32) (memory.size))

///|
extern "wasm" fn memory_grow(pages : Int) -> Int =
  #|(func (param i32) (result i32) (memory.grow (local.get 0)))

///|
/// reserve grows the memory to hold at least n bytes.
fn reserve(n : Int) -> Unit {
  let more = (n + 65535) / 65536 - memory_size()
  if more > 0 {
    ignore(memory_grow(more))
  }
}

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
      let s = Ok(@site.Site::embedded(base_url=base)) catch {
        e => Err("\{e}")
      }
      site.val = Some(s)
      s
    }
  }
}

///|
/// answer parses the request "base\nmethod\nquery\npath" and returns the
/// response as "status\nname\tvalue\n...\n\n" and the body.
fn answer(req : String) -> (String, String) {
  let parts = []
  let mut start = 0
  for i in 0..<req.length() {
    if parts.length() < 3 && req.code_unit_at(i) == '\n' {
      parts.push(req.unsafe_substring(start~, end=i))
      start = i + 1
    }
  }
  let p = req.unsafe_substring(start~, end=req.length())
  let res = match load(parts[0]) {
    Ok(s) => s.render(p, query=parts[2], verb=parts[1])
    Err(msg) => @http.Response::text(500, "\{msg}\n")
  }
  let head = StringBuilder()
  head.write_string("\{res.status}\n")
  for (name, value) in res.headers {
    head.write_string("\{name}\t\{value}\n")
  }
  head.write_char('\n')
  (head.to_string(), res.body.text())
}
