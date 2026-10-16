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
struct Site {
  base_url : String // absolute, without a trailing slash
  posts : Array[Post]
  by_slug : Map[String, Post]
  by_file : Map[String, Post] // by file path in the repository, for links
  docs : Array[Doc]
  by_path : Map[String, Doc]
  by_source : Map[String, Doc]
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
/// render answers the request for path, with query the raw query string
/// (without "?"), which only redirects keep. Like the Go blog, it answers
/// only GET and HEAD (verb is the HTTP method; `method` is reserved), and
/// any other method gets the 404 page.
pub fn Site::render(
  self : Site,
  path : String,
  query~ : String = "",
  verb~ : String = "GET",
) -> Response {
  if verb != "GET" && verb != "HEAD" {
    return Response::page(404, error_page(404, "Page not found."))
  }
  // Redirect like ServeMux: to the cleaned path, and from a directory
  // without its trailing slash.
  let c = clean_path(path)
  if c != path || c == "/docs" {
    return Response::redirect(if c == "/docs" { "/docs/" } else { c }, query~)
  }
  match path {
    "/" => Response::page(200, self.post_list())
    "/docs/" => Response::page(200, self.doc_list())
    "/favicon.svg" =>
      // Pages link to it without a version, so it is cached for a day.
      {
        status: 200,
        headers: [
          ("content-type", "image/svg+xml"),
          ("cache-control", "public, max-age=86400"),
        ],
        body: @assets.favicon_svg,
      }
    "/site.css" =>
      // Pages link to it with a version in the query, so it can be cached
      // for long.
      {
        status: 200,
        headers: [
          ("content-type", "text/css; charset=utf-8"),
          ("cache-control", "public, max-age=31536000, immutable"),
        ],
        body: @assets.site_css,
      }
    [.. "/posts/", .. slug] if !slug.contains("/") && slug is [.. s, .. ".md"] =>
      match self.by_slug.get(s.to_owned()) {
        Some(p) => Response::markdown(p.markdown)
        None => Response::page(404, error_page(404, "Post not found."))
      }
    [.. "/posts/", .. slug] if slug != "" && !slug.contains("/") =>
      match self.by_slug.get(slug.to_owned()) {
        Some(p) => Response::page(200, self.post_page(p))
        None => Response::page(404, error_page(404, "Post not found."))
      }
    [.. "/docs/", .. p] if p is [.. p, .. ".md"] =>
      match self.by_path.get(p.to_owned()) {
        Some(d) => Response::markdown(d.markdown)
        None => Response::page(404, error_page(404, "Document not found."))
      }
    [.. "/docs/", .. p] =>
      match self.by_path.get(p.to_owned()) {
        Some(d) => Response::page(200, self.doc_page(d))
        None => Response::page(404, error_page(404, "Document not found."))
      }
    _ => Response::page(404, error_page(404, "Page not found."))
  }
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
/// Response::markdown sends src as text. nosniff keeps browsers from
/// guessing that Markdown containing tags is HTML.
fn Response::markdown(src : String) -> Response {
  {
    status: 200,
    headers: [
      ("content-type", "text/markdown; charset=utf-8"),
      ("x-content-type-options", "nosniff"),
    ],
    body: src,
  }
}

///|
/// Response::redirect is a 307 to path, a cleaned path, with query, as
/// Go's http.Redirect writes it for a GET: the Location header and a short
/// HTML body linking to it.
fn Response::redirect(path : String, query~ : String) -> Response {
  let url = if query == "" {
    escape(path, fragment=false)
  } else {
    "\{escape(path, fragment=false)}?\{query}"
  }
  let location = hex_escape_non_ascii(url)
  {
    status: 307,
    headers: [
      ("location", location),
      ("content-type", "text/html; charset=utf-8"),
    ],
    body: "<a href=\"\{@el.render_html(@el.Text(url))}\">Temporary Redirect</a>.\n\n",
  }
}
