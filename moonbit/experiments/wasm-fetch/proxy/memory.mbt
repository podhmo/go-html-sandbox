// Reading and writing the linear memory, as ../../../http/wasm does,
// for the strings that cross host_fetch.

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
/// write_text writes s in UTF-8 at address 0 and returns its length.
fn write_text(s : String) -> Int32 {
  let b = @utf8.encode(s)
  let more = (b.length() + 65535) / 65536 - memory_size()
  if more > 0 {
    ignore(memory_grow(more))
  }
  for i, x in b {
    store8(i, x.to_int())
  }
  b.length()
}

///|
/// read_text decodes the n bytes of UTF-8 at address 0.
fn read_text(n : Int32) -> String {
  @utf8.decode_lossy(Bytes::makei(n, i => load8(i).to_byte()))
}
