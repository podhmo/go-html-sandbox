// The blog as the Worker serves it: a port of the Go blog's server.go,
// without the HTTP server. render answers a path with a Response, which
// the worker package hands to the host.

///|
/// Response is what the site answers to a request.
pub struct Response {
  status : Int32
  headers : Array[(String, String)]
  body : String
}

///|
/// Response::page renders n as a full HTML document with status.
fn Response::page(status : Int32, n : @el.Node) -> Response {
  {
    status,
    headers: [("content-type", "text/html; charset=utf-8")],
    body: "<!doctype html>\n\{@el.render_html(n)}",
  }
}

///|
/// Response::text is body as plain text with status.
pub fn Response::text(status : Int32, body : String) -> Response {
  { status, headers: [("content-type", "text/plain; charset=utf-8")], body, }
}

///|
/// Site is the content being served.
pub struct Site {
  base_url : String // absolute, without a trailing slash
  posts : Array[Post]
  by_slug : Map[String, Post]
  by_file : Map[String, Post] // by file path in the repository, for links
  docs : Array[Doc]
  by_source : Map[String, Doc]
}

///|
/// Site::new serves posts and docs. base_url is the public origin used for
/// absolute URLs in OGP tags, e.g. "https://example.com". Path prefixes
/// are rejected because links inside the site are root-relative.
pub fn Site::new(
  base_url~ : String,
  posts~ : Array[Post],
  docs~ : Array[Doc],
) -> Site raise LoadError {
  let origin = base_url.strip_suffix("/").unwrap_or(base_url)
  let host = if origin.strip_prefix("https://") is Some(h) {
    h
  } else {
    origin.strip_prefix("http://").unwrap_or("")
  }
  if host == "" ||
    host.contains("/") ||
    host.contains("?") ||
    host.contains("#") {
    raise LoadError(
      "base URL must be an http(s) origin such as https://example.com, got \{base_url.escape()}",
    )
  }
  let by_slug = Map([])
  let by_file = Map([])
  for p in posts {
    by_slug[p.slug] = p
    by_file[post_source(p)] = p
  }
  let by_source = Map([])
  for d in docs {
    by_source[d.source] = d
  }
  { base_url: origin.to_owned(), posts, by_slug, by_file, docs, by_source, }
}

///|
/// Site::embedded serves the posts and documents built into the Wasm.
pub fn Site::embedded(base_url~ : String) -> Site raise LoadError {
  Site::new(
    base_url~,
    posts=load_posts(@posts.files),
    docs=load_docs(@repodocs.files),
  )
}

///|
/// render answers the request for path.
pub fn Site::render(self : Site, path : String) -> Response {
  match path {
    "/" => Response::page(200, self.post_list())
    [.. "/posts/", .. slug] if slug != "" && !slug.contains("/") =>
      match self.by_slug.get(slug.to_owned()) {
        Some(p) => Response::page(200, self.post_page(p))
        None => Response::page(404, error_page(404, "Post not found."))
      }
    _ => Response::page(404, error_page(404, "Page not found."))
  }
}
