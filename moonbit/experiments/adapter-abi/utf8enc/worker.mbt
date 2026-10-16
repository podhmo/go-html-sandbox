///|
fn write8(at : Int32, s : String) -> Int32 {
  let b = @utf8.encode(s)
  reserve(at + b.length())
  for i in 0..<b.length() {
    store8(at + i, b[i].to_int())
  }
  at + b.length()
}

///|
/// serve reads the request, n UTF-8 bytes at address 0, and writes the
/// response there in UTF-8, returning its length in bytes.
pub fn serve(n : Int32) -> Int32 {
  let req = @utf8.decode(Bytes::makei(n, i => load8(i).to_byte())) catch {
    _ => ""
  }
  let (head, body) = answer(req)
  write8(write8(0, head), body)
}
