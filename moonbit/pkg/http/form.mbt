// Form bodies: application/x-www-form-urlencoded and multipart/form-data.

///|
/// File is a file field of a multipart form.
pub struct File {
  name : String
  filename : String
  content_type : String
  data : Bytes
}

///|
/// Form is a parsed form body: the fields that are not files, and the
/// files.
pub struct Form {
  values : Values
  files : Array[File]
}

///|
/// Request::form parses the body as a urlencoded or a multipart form, as
/// its Content-Type says. It raises BadRequest for any other type or a
/// malformed multipart body. The query string is not included.
pub fn Request::form(self : Request) -> Form raise BadRequest {
  let (ty, params) = media_type(self.headers.get("content-type").unwrap_or(""))
  match ty {
    "application/x-www-form-urlencoded" =>
      { values: parse_values(self.text()), files: [], }
    "multipart/form-data" =>
      match params.search_by(p => p.0 == "boundary") {
        Some(i) if params[i].1 != "" => parse_multipart(self.body, params[i].1)
        _ => raise BadRequest("multipart form without a boundary")
      }
    _ => raise BadRequest("not a form: \{ty.escape()}")
  }
}

///|
/// parse_multipart splits body into its parts at boundary (RFC 7578).
/// Parts without a name are skipped.
fn parse_multipart(
  body : BytesView,
  boundary : String,
) -> Form raise BadRequest {
  let delim = @utf8.encode("--\{boundary}")
  let next = @utf8.encode("\r\n--\{boundary}")
  let crlf : Bytes = b"\r\n"
  let blank : Bytes = b"\r\n\r\n"
  guard body.find(delim) is Some(first) else {
    raise BadRequest("multipart form without its boundary")
  }
  let values = []
  let files = []
  let mut pos = first + delim.length()
  while true {
    let rest = body[pos:]
    if rest.has_prefix(b"--") {
      break
    }
    guard rest.has_prefix(crlf) else {
      raise BadRequest("malformed multipart boundary")
    }
    let rest = rest[2:]
    // A part with no headers starts with the blank line right away.
    let (head, content_at) = if rest.has_prefix(crlf) {
      ("", 2)
    } else {
      guard rest.find(blank) is Some(h) else {
        raise BadRequest("multipart part without a blank line")
      }
      (@utf8.decode_lossy(rest[:h]), h + 4)
    }
    guard rest[content_at:].find(next) is Some(len) else {
      raise BadRequest("multipart part without a closing boundary")
    }
    let data = rest[content_at:content_at + len]
    pos = pos + 2 + content_at + len + next.length()
    let headers = Headers::new()
    for line in head.split("\r\n") {
      if line.find(":") is Some(i) {
        headers.add(
          line[:i].to_owned(),
          line[i + 1:].trim(chars=" \t").to_owned(),
        )
      }
    }
    let (_, disp) = media_type(headers.get("content-disposition").unwrap_or(""))
    let param = (name : String) => {
      match disp.search_by(p => p.0 == name) {
        Some(i) => Some(disp[i].1)
        None => None
      }
    }
    guard param("name") is Some(name) else { continue }
    match param("filename") {
      Some(filename) =>
        files.push({
          name,
          filename,
          content_type: headers
          .get("content-type")
          .unwrap_or("application/octet-stream"),
          data: data.to_owned(),
        })
      None => values.push((name, @utf8.decode_lossy(data)))
    }
  }
  { values: { pairs: values, }, files, }
}
