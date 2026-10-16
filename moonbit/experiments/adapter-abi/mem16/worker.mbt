///|
fn write16(at : Int32, s : String) -> Int32 {
  for i in 0..<s.length() {
    store16(at + i * 2, s.code_unit_at(i).to_int())
  }
  at + s.length() * 2
}

///|
/// serve reads the request, n UTF-16 code units at address 0, and writes
/// the response there in UTF-16, returning its length in code units.
pub fn serve(n : Int32) -> Int32 {
  let sb = StringBuilder()
  for i in 0..<n {
    sb.write_char(load16(i * 2).unsafe_to_char())
  }
  let (head, body) = answer(sb.to_string())
  reserve((head.length() + body.length()) * 2)
  let end = write16(write16(0, head), body)
  end / 2
}
