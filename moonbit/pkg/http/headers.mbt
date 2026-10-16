// Header fields, as a list so that a name can repeat (Set-Cookie).

///|
/// Headers are the header fields of a request or a response, in order.
/// Names are compared without case; the host gives request headers in
/// lower case.
pub struct Headers {
  fields : Array[(String, String)]
}

///|
pub fn Headers::Headers(fields~ : Array[(String, String)] = []) -> Headers {
  { fields, }
}

///|
/// Headers::get is the first value for name.
pub fn Headers::get(self : Headers, name : String) -> String? {
  let name = name.to_lower()
  for (n, v) in self.fields {
    if n.to_lower() == name {
      return Some(v)
    }
  }
  None
}

///|
/// Headers::get_all is every value for name, in order.
pub fn Headers::get_all(self : Headers, name : String) -> Array[String] {
  let name = name.to_lower()
  self.fields.filter(f => f.0.to_lower() == name).map(f => f.1)
}

///|
/// Headers::add appends a field, keeping those with the same name.
pub fn Headers::add(self : Headers, name : String, value~ : String) -> Unit {
  self.fields.push((name, value))
}

///|
/// Headers::set replaces the fields named name with one.
pub fn Headers::set(self : Headers, name : String, value~ : String) -> Unit {
  self.delete(name)
  self.fields.push((name, value))
}

///|
/// Headers::delete removes the fields named name.
pub fn Headers::delete(self : Headers, name : String) -> Unit {
  let lower = name.to_lower()
  self.fields.retain(f => f.0.to_lower() != lower)
}

///|
/// Headers::iter is the fields in order.
pub fn Headers::iter(self : Headers) -> Iter[(String, String)] {
  self.fields.iter()
}

///|
/// media_type is the media type of a Content-Type value, in lower case,
/// and its parameters (with their names in lower case), e.g.
/// ("multipart/form-data", [("boundary", "x")]).
pub fn media_type(value : String) -> (String, Array[(String, String)]) {
  let parts = value.split(";").collect()
  let params = []
  for part in parts[1:] {
    guard part.find("=") is Some(i) else { continue }
    let name = part[:i].trim(chars=" \t").to_owned().to_lower()
    let mut v = part[i + 1:].trim(chars=" \t")
    if v is [.. "\"", .. inner, .. "\""] {
      v = inner
    }
    params.push((name, v.to_owned()))
  }
  let ty = if parts.is_empty() {
    ""
  } else {
    parts[0].trim(chars=" \t").to_owned()
  }
  (ty.to_lower(), params)
}
