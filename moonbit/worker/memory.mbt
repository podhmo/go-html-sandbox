// The linear memory the host and the Wasm share. moon emits one page of it
// even for wasm-gc and leaves it unused, so the whole of it is the
// request and response buffer.

///|
extern "wasm" fn load8(addr : Int32) -> Int32 =
  #|(func (param i32) (result i32) (i32.load8_u (local.get 0)))

///|
extern "wasm" fn store8(addr : Int32, v : Int32) =
  #|(func (param i32) (param i32) (i32.store8 (local.get 0) (local.get 1)))

///|
extern "wasm" fn memory_size() -> Int32 =
  #|(func (result i32) (memory.size))

///|
extern "wasm" fn memory_grow(pages : Int32) -> Int32 =
  #|(func (param i32) (result i32) (memory.grow (local.get 0)))

///|
/// reserve grows the memory to hold at least n bytes.
fn reserve(n : Int32) -> Unit {
  let more = (n + 65535) / 65536 - memory_size()
  if more > 0 {
    ignore(memory_grow(more))
  }
}

///|
/// read decodes the n bytes of UTF-8 at address 0.
fn read(n : Int32) -> String {
  @utf8.decode(Bytes::makei(n, i => load8(i).to_byte())) catch {
    _ => ""
  }
}

///|
/// write encodes s in UTF-8 at address at, and returns where it ends.
fn write(at : Int32, s : String) -> Int32 {
  reserve(at + s.length() * 3)
  let n = s.length()
  let mut p = at
  let mut i = 0
  while i < n {
    let mut c = s.code_unit_at(i).to_int()
    i += 1
    if c is (0xD800..<0xDC00) && i < n {
      let d = s.code_unit_at(i).to_int()
      if d is (0xDC00..<0xE000) {
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
