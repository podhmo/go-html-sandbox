///|
test "write encodes UTF-8" {
  for s in ["", "abc", "é日本", "😀a"] {
    let end = write(0, s)
    assert_eq(read(end), @utf8.encode(s))
  }
  // An unpaired surrogate is written as its own three bytes.
  let lone = String::from_array([(0xD800).unsafe_to_char(), 'a'])
  assert_eq(read(write(0, lone)), b"\xED\xA0\x80a")
  let lone = String::from_array(['a', (0xDC00).unsafe_to_char()])
  assert_eq(read(write(0, lone)), b"a\xED\xB0\x80")
  // It starts at its address.
  assert_eq(write(3, "日"), 6)
  assert_eq(read(6)[3:], b"\xE6\x97\xA5")
}
