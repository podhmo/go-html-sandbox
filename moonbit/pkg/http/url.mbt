// Decoding the parts of a request URL: the path, and the query string or
// a urlencoded form body.

///|
/// unescape decodes the %XX escapes in s, and "+" as a space when plus is
/// true (as in a query string or a urlencoded form). It returns None for
/// a malformed escape. Bytes that are not UTF-8 become U+FFFD, since a
/// String cannot hold them.
pub fn unescape(s : StringView, plus~ : Bool = false) -> String? {
  guard s.contains("%") || (plus && s.contains("+")) else {
    return Some(s.to_owned())
  }
  let bytes = Buffer()
  for i = 0; i < s.length(); {
    let c = s[i]
    if c == '%' {
      guard i + 2 < s.length() &&
        hex_value(s[i + 1]) is Some(hi) &&
        hex_value(s[i + 2]) is Some(lo) else {
        return None
      }
      bytes.write_byte((hi * 16 + lo).to_byte())
      continue i + 3
    }
    if plus && c == '+' {
      bytes.write_byte(b' ')
      continue i + 1
    }
    let end = match s[i:].find_by(c => c == '%' || (plus && c == '+')) {
      Some(j) => i + j
      None => s.length()
    }
    bytes.write_bytes(@utf8.encode(s[i:end]))
    continue end
  }
  Some(@utf8.decode_lossy(bytes.to_bytes()))
}

///|
fn hex_value(c : UInt16) -> Int32? {
  let n = c.to_int()
  match c {
    '0'..<='9' => Some(n - '0'.to_int())
    'a'..<='f' => Some(n - 'a'.to_int() + 10)
    'A'..<='F' => Some(n - 'A'.to_int() + 10)
    _ => None
  }
}

///|
/// Values is an ordered list of names and values, as a query string or a
/// form has them. A name may appear more than once.
pub struct Values {
  pairs : Array[(String, String)]
}

///|
/// Values::get is the first value for name.
pub fn Values::get(self : Values, name : String) -> String? {
  for (n, v) in self.pairs {
    if n == name {
      return Some(v)
    }
  }
  None
}

///|
/// Values::get_all is every value for name, in order.
pub fn Values::get_all(self : Values, name : String) -> Array[String] {
  self.pairs.filter(p => p.0 == name).map(p => p.1)
}

///|
/// parse_values parses "a=1&b=2&a=3", a query string or a urlencoded form.
/// A pair without "=" has an empty value. Pairs whose escapes are
/// malformed are skipped, so one bad pair does not lose the rest.
pub fn parse_values(s : StringView) -> Values {
  let pairs = []
  for part in s.split("&") {
    if part.is_empty() {
      continue
    }
    let (k, v) = match part.find("=") {
      Some(i) => (part[:i], part[i + 1:])
      None => (part, "")
    }
    if (unescape(k, plus=true), unescape(v, plus=true)) is (Some(k), Some(v)) {
      pairs.push((k, v))
    }
  }
  { pairs, }
}
