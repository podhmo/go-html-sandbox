// The linear memory the host and the Wasm share. moon emits one page of it
// even for wasm-gc and leaves it unused, so the whole of it is the
// request and response buffer. The package that exports the entry point
// must export it too ("export-memory-name": "memory").

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
/// read copies the n bytes at address 0.
fn read(n : Int32) -> Bytes {
  Bytes::makei(n, i => load8(i).to_byte())
}

///|
/// write_bytes copies b to address at, and returns where it ends.
fn write_bytes(at : Int32, b : Bytes) -> Int32 {
  reserve(at + b.length())
  for i, x in b {
    store8(at + i, x.to_int())
  }
  at + b.length()
}

///|
/// write encodes s in UTF-8 at address at, and returns where it ends.
fn write(at : Int32, s : String) -> Int32 {
  reserve(at + s.length() * 3)
  // Iterating a String joins each surrogate pair into one Char, and gives
  // an unpaired surrogate as it is, which is written as three bytes.
  for ch in s; p = at {
    let c = ch.to_int()
    if c < 0x80 {
      store8(p, c)
      continue p + 1
    } else if c < 0x800 {
      store8(p, 0xC0 | (c >> 6))
      store8(p + 1, 0x80 | (c & 0x3F))
      continue p + 2
    } else if c < 0x10000 {
      store8(p, 0xE0 | (c >> 12))
      store8(p + 1, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 2, 0x80 | (c & 0x3F))
      continue p + 3
    } else {
      store8(p, 0xF0 | (c >> 18))
      store8(p + 1, 0x80 | ((c >> 12) & 0x3F))
      store8(p + 2, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 3, 0x80 | (c & 0x3F))
      continue p + 4
    }
  } nobreak {
    p
  }
}
