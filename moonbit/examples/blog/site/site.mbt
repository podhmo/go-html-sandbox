// The blog as the Worker serves it: a port of the Go blog's server.go,
// without the HTTP server. Site::handle answers an @http.Request with an
// @http.Response, routing with an @http.Router.

///|
/// page renders n as a full HTML document with status.
fn page(status : Int32, n : @el.Node) -> @http.Response {
  @http.Response::html(status, "<!doctype html>\n\{@el.render_html(n)}")
}

///|
/// not_found is the 404 page saying message.
fn not_found(message : String) -> @http.Response {
  page(404, error_page(404, message))
}

///|
/// Site is the content being served.
struct Site {
  base_url : String // absolute, without a trailing slash
  posts : Array[Post]
  by_slug : Map[String, Post]
  by_file : Map[String, Post] // by file path in the repository, for links
  docs : Array[Doc]
  by_path : Map[String, Doc]
  by_source : Map[String, Doc]
  mut router : @http.Router? // made on the first request
}

///|
/// Site::Site serves posts and docs. base_url is the public origin used for
/// absolute URLs in OGP tags, e.g. "https://example.com". Path prefixes
/// are rejected because links inside the site are root-relative.
pub fn Site::Site(
  base_url~ : String,
  posts~ : Array[Post],
  docs~ : Array[Doc],
) -> Site raise LoadError {
  let origin = base_url.strip_suffix("/").unwrap_or(base_url)
  let host = match origin {
    [.. "https://", .. h] | [.. "http://", .. h] => h
    _ => ""
  }
  if host == "" || host.contains_any(chars="/?#") {
    raise LoadError(
      message="base URL must be an http(s) origin such as https://example.com, got \{base_url.escape()}",
    )
  }
  let by_slug = Map([])
  let by_file = Map([])
  for p in posts {
    by_slug[p.slug] = p
    by_file[p.source()] = p
  }
  let by_path = Map([])
  let by_source = Map([])
  for d in docs {
    by_path[d.path] = d
    by_source[d.source] = d
  }
  {
    base_url: origin.to_owned(),
    posts,
    by_slug,
    by_file,
    docs,
    by_path,
    by_source,
    router: None,
  }
}

///|
/// Site::embedded serves the posts and documents built into the Wasm.
pub fn Site::embedded(base_url~ : String) -> Site raise LoadError {
  Site(
    base_url~,
    posts=load_posts(@posts.files),
    docs=load_docs(@repodocs.files),
  )
}

///|
/// handle answers req. Like the Go blog, it answers only GET and HEAD, and
/// any other method gets the 404 page, before the redirects.
pub fn Site::handle(self : Site, req : @http.Request) -> @http.Response {
  if req.verb != "GET" && req.verb != "HEAD" {
    return not_found("Page not found.")
  }
  // Redirect like ServeMux: to the cleaned path, and from a directory
  // without its trailing slash.
  let path = req.path
  let c = clean_path(path)
  if c != path || c == "/docs" {
    return redirect(
      if c == "/docs" {
        "/docs/"
      } else {
        c
      },
      query=req.raw_query,
    )
  }
  let router = match self.router {
    Some(r) => r
    None => {
      let r = self.new_router()
      self.router = Some(r)
      r
    }
  }
  router.serve(req)
}

///|
/// new_router routes the paths of the Go blog. It matches the decoded
/// path, as the Go blog's route does with r.URL.Path, so "/docs%2F" is
/// "/docs/".
fn Site::new_router(self : Site) -> @http.Router {
  let r = @http.Router(decoded_path=true, not_found=_ => {
    not_found("Page not found.")
  })
  r.handle("GET /{$}", _ => page(200, self.post_list()))
  r.handle("GET /docs/{$}", _ => page(200, self.doc_list()))
  // Pages link to it without a version, so it is cached for a day.
  r.handle("GET /favicon.svg", _ => {
    @http.Response::typed(200, "image/svg+xml", Text(@assets.favicon_svg))..header(
      "cache-control",
      value="public, max-age=86400",
    )
  })
  // Pages link to it with a version in the query, so it can be cached for
  // long.
  r.handle("GET /site.css", _ => {
    @http.Response::typed(
      200,
      "text/css; charset=utf-8",
      Text(@assets.site_css),
    )..header("cache-control", value="public, max-age=31536000, immutable")
  })
  // A pattern cannot end in ".md" after a wildcard, so the handlers look
  // at the suffix.
  r.handle("GET /posts/{slug}", req => {
    let slug = req.param("slug")
    match slug {
      [.. s, .. ".md"] =>
        match self.by_slug.get(s.to_owned()) {
          Some(p) => markdown(p.markdown)
          None => not_found("Post not found.")
        }
      _ =>
        match self.by_slug.get(slug) {
          Some(p) => page(200, self.post_page(p))
          None => not_found("Post not found.")
        }
    }
  })
  r.handle("GET /docs/{path...}", req => {
    let path = req.param("path")
    match path {
      [.. p, .. ".md"] =>
        match self.by_path.get(p.to_owned()) {
          Some(d) => markdown(d.markdown)
          None => not_found("Document not found.")
        }
      _ =>
        match self.by_path.get(path) {
          Some(d) => page(200, self.doc_page(d))
          None => not_found("Document not found.")
        }
    }
  })
  r
}

///|
/// render answers the request for path, a decoded path, with query the
/// raw query string (without "?"), and verb the method. It is handle for
/// a request made of them.
pub fn Site::render(
  self : Site,
  path : String,
  query~ : String = "",
  verb~ : String = "GET",
) -> @http.Response {
  let url = if query == "" {
    escape(path, fragment=false)
  } else {
    "\{escape(path, fragment=false)}?\{query}"
  }
  let req = @http.Request(verb~, url~) catch {
    // escape writes only well-formed escapes.
    e => abort("\{e}")
  }
  self.handle(req)
}

///|
/// clean_path is p without "." and ".." elements and repeated slashes. A
/// trailing slash is kept.
fn clean_path(p : String) -> String {
  let c = clean("/\{p}")
  if p.has_suffix("/") && c != "/" {
    "\{c}/"
  } else {
    c
  }
}

///|
/// markdown sends src as text. nosniff keeps browsers from guessing that
/// Markdown containing tags is HTML.
fn markdown(src : String) -> @http.Response {
  @http.Response::typed(200, "text/markdown; charset=utf-8", Text(src))..header(
    "x-content-type-options",
    value="nosniff",
  )
}

///|
/// redirect is a 307 to path, a cleaned path, with query, as Go's
/// http.Redirect writes it for a GET: the Location header and a short
/// HTML body linking to it.
fn redirect(path : String, query~ : String) -> @http.Response {
  let url = if query == "" {
    escape(path, fragment=false)
  } else {
    "\{escape(path, fragment=false)}?\{query}"
  }
  let location = hex_escape_non_ascii(url)
  @http.Response(
    307,
    headers=@http.Headers(fields=[
      ("location", location),
      ("content-type", "text/html; charset=utf-8"),
    ]),
    body=Text(
      "<a href=\"\{@el.render_html(@el.Text(url))}\">Temporary Redirect</a>.\n\n",
    ),
  )
}
