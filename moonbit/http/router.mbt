// Routing by patterns, in the spirit of Go 1.22's ServeMux: an optional
// method, then a path whose segments are literals, {name} (one segment),
// {name...} (the rest), or {$} (the end). A pattern ending in "/" matches
// every path under it.

///|
/// Handler answers a request.
pub type Handler = (Request) -> Response

///|
priv enum Segment {
  Literal(String)
  Wildcard(String)
  Rest(String)
  End
}

///|
priv struct Route {
  verb : String? // None matches every method
  segments : Array[Segment]
  subtree : Bool // the pattern ends in "/" without {$}
  handler : Handler
}

///|
/// Router dispatches a request to the handler of the most specific pattern
/// that matches it. A path that matches only patterns for other methods
/// gets method_not_allowed (405 with Allow by default), and one that
/// matches none gets not_found (404 by default).
pub struct Router {
  priv routes : Array[Route]
  decoded_path : Bool
  not_found : Handler
  method_not_allowed : (Request, Array[String]) -> Response
}

///|
/// Router::new is a router without routes. not_found and
/// method_not_allowed (given the methods the path allows) replace the
/// default answers. Patterns match the path split at "/" and then
/// decoded, as Go 1.22's ServeMux does, so "%2F" stays inside a segment;
/// with decoded_path, they match the decoded path split at "/", as a
/// handler routing on Go's r.URL.Path by hand does.
pub fn Router::new(
  decoded_path~ : Bool = false,
  not_found~ : Handler = _ => Response::text(404, "404 page not found\n"),
  method_not_allowed~ : (Request, Array[String]) -> Response = (_, allow) => {
    Response::text(405, "Method Not Allowed\n").header(
      "allow",
      allow.join(", "),
    )
  },
) -> Router {
  { routes: [], decoded_path, not_found, method_not_allowed, }
}

///|
/// Router::handle registers handler for pattern, "[METHOD ]/path". A GET
/// pattern also matches HEAD. Of patterns that are equally specific, the
/// first registered wins. It aborts on a malformed pattern.
pub fn Router::handle(
  self : Router,
  pattern : String,
  handler : Handler,
) -> Unit {
  let (verb, path) = match pattern.find(" ") {
    Some(i) =>
      (Some(pattern[:i].to_owned()), pattern[i + 1:].trim(chars=" ").to_owned())
    None => (None, pattern)
  }
  guard path.has_prefix("/") else {
    abort("pattern must start with a path: \{pattern.escape()}")
  }
  let parts = path[1:].split("/").collect()
  let segments = []
  let mut subtree = false
  for i, part in parts {
    let last = i == parts.length() - 1
    match part {
      "" if last => subtree = true
      "{$}" if last => segments.push(End)
      [.. "{", .. name, .. "...}"] if last =>
        segments.push(Rest(name.to_owned()))
      [.. "{", .. name, .. "}"] => segments.push(Wildcard(name.to_owned()))
      _ => segments.push(Literal(part.to_owned()))
    }
  }
  let route = Route::{ verb, segments, subtree, handler, }
  // Keep the routes from the most specific, after the equal ones.
  let at = self.routes
    .search_by(r => more_specific(route, r))
    .unwrap_or(self.routes.length())
  self.routes.insert(at, route)
}

///|
/// rank orders the kinds of segment from the most specific.
fn rank(s : Segment?, subtree : Bool) -> Int32 {
  match s {
    Some(Literal(_)) => 4
    Some(End) => 3
    Some(Wildcard(_)) => 2
    Some(Rest(_)) => 1
    None => if subtree { 0 } else { -1 }
  }
}

///|
/// more_specific tells whether a matches fewer paths than b, comparing
/// segment by segment, and a method over none.
fn more_specific(a : Route, b : Route) -> Bool {
  let n = if a.segments.length() > b.segments.length() {
    a.segments.length()
  } else {
    b.segments.length()
  }
  // One past the longer, so that a subtree is less specific than the
  // same path alone.
  for i in 0..<=n {
    let ra = rank(a.segments.get(i), a.subtree)
    let rb = rank(b.segments.get(i), b.subtree)
    if ra != rb {
      return ra > rb
    }
  }
  a.verb is Some(_) && b.verb is None
}

///|
/// match_path matches the decoded segments of a path against route and
/// returns the wildcards' values.
fn Route::match_path(
  self : Route,
  segs : Array[String],
) -> Map[String, String]? {
  let params = Map([])
  for i, s in self.segments {
    match s {
      Literal(lit) =>
        if !(segs.get(i) is Some(seg) && seg == lit) {
          return None
        }
      Wildcard(name) => {
        guard segs.get(i) is Some(seg) && seg != "" else { return None }
        params[name] = seg
      }
      Rest(name) => {
        params[name] = segs[i:].join("/")
        return Some(params)
      }
      End => if !(i == segs.length() - 1 && segs[i] == "") { return None }
    }
  }
  let n = self.segments.length()
  if self.segments.last() is Some(End) {
    Some(params)
  } else if self.subtree {
    if segs.length() > n {
      Some(params)
    } else {
      None
    }
  } else if segs.length() == n {
    Some(params)
  } else {
    None
  }
}

///|
/// Router::serve answers req with the handler of the matching pattern,
/// filling req.params with the wildcards.
pub fn Router::serve(self : Router, req : Request) -> Response {
  let segs = []
  if self.decoded_path {
    req.path[1:].split("/").each(s => segs.push(s.to_owned()))
  } else {
    for raw in req.raw_path[1:].split("/") {
      segs.push(unescape(raw).unwrap_or(raw.to_owned()))
    }
  }
  let allow = []
  for r in self.routes {
    guard r.match_path(segs) is Some(params) else { continue }
    match r.verb {
      Some(v) if v != req.verb && !(v == "GET" && req.verb == "HEAD") => {
        if !allow.contains(v) {
          allow.push(v)
        }
        if v == "GET" && !allow.contains("HEAD") {
          allow.push("HEAD")
        }
      }
      _ => {
        req.params.clear()
        params.each((k, v) => req.params[k] = v)
        return (r.handler)(req)
      }
    }
  }
  if allow.is_empty() {
    (self.not_found)(req)
  } else {
    (self.method_not_allowed)(req, allow)
  }
}
