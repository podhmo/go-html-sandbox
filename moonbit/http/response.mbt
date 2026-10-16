// The response a handler returns.

///|
/// Body is a response body: text, sent as UTF-8, or bytes as they are.
pub(all) enum Body {
  Text(String)
  Binary(Bytes)
}

///|
/// Body::text is the body as text, decoding bytes as UTF-8 with U+FFFD
/// for those that are not.
pub fn Body::text(self : Body) -> String {
  match self {
    Text(s) => s
    Binary(b) => @utf8.decode_lossy(b)
  }
}

///|
/// Response is an HTTP response.
pub struct Response {
  status : Int32
  headers : Headers
  body : Body
}

///|
pub fn Response::new(
  status : Int32,
  headers~ : Headers = Headers::new(),
  body~ : Body = Text(""),
) -> Response {
  { status, headers, body, }
}

///|
/// Response::text is body as text/plain.
pub fn Response::text(status : Int32, body : String) -> Response {
  Response::typed(status, "text/plain; charset=utf-8", Text(body))
}

///|
/// Response::html is body as text/html.
pub fn Response::html(status : Int32, body : String) -> Response {
  Response::typed(status, "text/html; charset=utf-8", Text(body))
}

///|
/// Response::json is value as application/json.
pub fn Response::json(status : Int32, value : Json) -> Response {
  Response::typed(status, "application/json", Text(value.stringify()))
}

///|
/// Response::typed is body with the Content-Type content_type.
pub fn Response::typed(
  status : Int32,
  content_type : String,
  body : Body,
) -> Response {
  {
    status,
    headers: Headers::new(fields=[("content-type", content_type)]),
    body,
  }
}

///|
/// Response::redirect is a redirect to location, with status (such as 302,
/// 303, 307, or 308) and no body.
pub fn Response::redirect(status : Int32, location : String) -> Response {
  {
    status,
    headers: Headers::new(fields=[("location", location)]),
    body: Text(""),
  }
}

///|
/// Response::header adds a header field and returns the response, for
/// chaining.
pub fn Response::header(
  self : Response,
  name : String,
  value : String,
) -> Response {
  self.headers.add(name, value)
  self
}
