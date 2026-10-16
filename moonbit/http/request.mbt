// The request a handler sees.

///|
/// BadRequest is raised for a request that cannot be parsed, such as a
/// path with a malformed %XX escape. Hosts answer it with 400.
pub(all) suberror BadRequest {
  BadRequest(String)
}

///|
/// Request is an HTTP request. verb is the method; path is raw_path decoded; params are the
/// wildcards of the pattern the Router matched; env is what the host
/// passes besides the request, such as a Worker's string variables.
pub struct Request {
  verb : String // the method; `method` is reserved
  url : String
  host : String
  raw_path : String
  path : String
  raw_query : String
  headers : Headers
  body : Bytes
  env : Map[String, String]
  params : Map[String, String]
}

///|
/// Request::new parses url, either absolute ("https://host/path?q") or
/// only the path and the query, and decodes the path. It raises
/// BadRequest when the path has a malformed escape.
pub fn Request::new(
  verb~ : String,
  url~ : String,
  headers~ : Headers = Headers::new(),
  body~ : Bytes = b"",
  env~ : Map[String, String] = {},
) -> Request raise BadRequest {
  let mut rest = url[:]
  if rest.find("#") is Some(i) {
    rest = rest[:i]
  }
  let mut host = ""
  if rest.find("://") is Some(i) {
    let after = rest[i + 3:]
    let end = after.find("/").unwrap_or(after.length())
    let end = match after[:end].find("?") {
      Some(q) => q
      None => end
    }
    host = after[:end].to_owned()
    rest = after[end:]
  }
  let (raw_path, raw_query) = match rest.find("?") {
    Some(i) => (rest[:i].to_owned(), rest[i + 1:].to_owned())
    None => (rest.to_owned(), "")
  }
  let raw_path = if raw_path == "" { "/" } else { raw_path }
  guard unescape(raw_path) is Some(path) else {
    raise BadRequest("malformed path \{raw_path.escape()}")
  }
  {
    verb,
    url,
    host,
    raw_path,
    path,
    raw_query,
    headers,
    body,
    env,
    params: {},
  }
}

///|
/// Request::query is the parsed query string.
pub fn Request::query(self : Request) -> Values {
  parse_values(self.raw_query)
}

///|
/// Request::param is the value of the wildcard name in the matched
/// pattern, or "" if there is none.
pub fn Request::param(self : Request, name : String) -> String {
  self.params.get(name).unwrap_or("")
}

///|
/// Request::text is the body decoded as UTF-8, with U+FFFD for bytes that
/// are not.
pub fn Request::text(self : Request) -> String {
  @utf8.decode_lossy(self.body)
}

///|
/// Request::json parses the body as JSON.
pub fn Request::json(self : Request) -> Json raise BadRequest {
  @json.parse(self.text()) catch {
    e => raise BadRequest("malformed JSON: \{e}")
  }
}
