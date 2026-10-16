///|
/// write8 encodes s in UTF-8 at address at, and returns the end.
fn write8(at : Int, s : String) -> Int {
  reserve(at + s.length() * 3)
  let mut p = at
  let n = s.length()
  let mut i = 0
  while i < n {
    let mut c = s.code_unit_at(i).to_int()
    i += 1
    if c >= 0xD800 && c < 0xDC00 && i < n {
      let d = s.code_unit_at(i).to_int()
      if d >= 0xDC00 && d < 0xE000 {
        c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00)
        i += 1
      }
    }
    if c < 0x80 {
      store8(p, c)
      p += 1
    } else if c < 0x800 {
      store8(p, 0xC0 | (c >> 6))
      store8(p + 1, 0x80 | (c & 0x3F))
      p += 2
    } else if c < 0x10000 {
      store8(p, 0xE0 | (c >> 12))
      store8(p + 1, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 2, 0x80 | (c & 0x3F))
      p += 3
    } else {
      store8(p, 0xF0 | (c >> 18))
      store8(p + 1, 0x80 | ((c >> 12) & 0x3F))
      store8(p + 2, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 3, 0x80 | (c & 0x3F))
      p += 4
    }
  }
  p
}

///|
pub fn serve(n : Int) -> Int {
  let req = @utf8.decode(Bytes::makei(n, i => load8(i).to_byte())) catch {
    _ => ""
  }
  let (head, body) = answer(req)
  write8(write8(0, head), body)
}
