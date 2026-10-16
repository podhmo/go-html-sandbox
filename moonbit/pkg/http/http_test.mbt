///|
fn request(
  verb : String,
  url : String,
  headers~ : Array[(String, String)] = [],
  body~ : String = "",
) -> @http.Request raise {
  @http.Request(
    verb~,
    url~,
    headers=@http.Headers(fields=headers),
    body=@utf8.encode(body),
  )
}

///|
fn body_text(res : @http.Response) -> String {
  res.body.text()
}

///|
fn raises(f : () -> Unit raise) -> Bool {
  try f() catch {
    _ => true
  } noraise {
    _ => false
  }
}

///|
test "unescape" {
  assert_eq(@http.unescape("/a%20b+c"), Some("/a b+c"))
  assert_eq(@http.unescape("a%20b+c", plus=true), Some("a b c"))
  assert_eq(@http.unescape("%E6%97%A5"), Some("日"))
  assert_eq(@http.unescape("%FF"), Some("\u{FFFD}"))
  assert_eq(@http.unescape("%zz"), None)
  assert_eq(@http.unescape("%A"), None)
}

///|
test "unescape paths" {
  let cases : Array[(String, String?)] = [
    ("/", Some("/")),
    ("/a%3Cb%3E", Some("/a<b>")),
    ("/%E6%97%A5%E6%9C%AC", Some("/日本")),
    ("/docs%2F", Some("/docs/")),
    ("/%FF", Some("/\u{FFFD}")),
    ("/%E0%A4%A", None),
    ("/%zz", None),
    ("/%", None),
  ]
  for (raw, want) in cases {
    assert_eq(@http.unescape(raw), want, msg=raw)
  }
}

///|
test "parse_values" {
  let v = @http.parse_values("a=1&b=x+y&a=%E6%97%A5&flag&&bad=%zz&=e")
  assert_eq(v.pairs, [
    ("a", "1"),
    ("b", "x y"),
    ("a", "日"),
    ("flag", ""),
    ("", "e"),
  ])
  assert_eq(v.get("a"), Some("1"))
  assert_eq(v.get_all("a"), ["1", "日"])
  assert_eq(v.get("missing"), None)
}

///|
test "Request::Request parses the URL" {
  let r = request("GET", "https://example.com:8787/a%20b/c?x=1&y=2#frag")
  assert_eq(r.host, "example.com:8787")
  assert_eq(r.raw_path, "/a%20b/c")
  assert_eq(r.path, "/a b/c")
  assert_eq(r.raw_query, "x=1&y=2")
  assert_eq(r.query().get("y"), Some("2"))
  let r = request("GET", "http://h?q")
  assert_eq((r.raw_path, r.raw_query), ("/", "q"))
  let r = request("GET", "/only/path")
  assert_eq((r.host, r.path), ("", "/only/path"))
  try request("GET", "http://h/%zz") catch {
    e => assert_true(e is @http.BadRequest(_))
  } noraise {
    _ => fail("a malformed path must raise")
  }
}

///|
test "Headers" {
  let h = @http.Headers(fields=[("Content-Type", "text/plain")])
  assert_eq(h.get("content-type"), Some("text/plain"))
  h.add("set-cookie", "a=1")
  h.add("Set-Cookie", "b=2")
  assert_eq(h.get_all("SET-COOKIE"), ["a=1", "b=2"])
  h.set("set-cookie", "c=3")
  assert_eq(h.get_all("set-cookie"), ["c=3"])
  h.delete("CONTENT-TYPE")
  assert_eq(h.get("content-type"), None)
  assert_eq(
    @http.media_type("Multipart/Form-Data; Boundary=\"a b\"; charset=utf-8"),
    ("multipart/form-data", [("boundary", "a b"), ("charset", "utf-8")]),
  )
}

///|
test "Request::text and json" {
  let r = request("POST", "/", body="{\"a\": [1, \"日\"]}")
  assert_eq(r.text(), "{\"a\": [1, \"日\"]}")
  assert_eq(r.json(), { "a": [1, "日"] })
  let r = request("POST", "/", body="{")
  assert_true(raises(() => ignore(r.json())))
}

///|
test "Request::form urlencoded" {
  let r = request(
    "POST",
    "/?q=1",
    headers=[("content-type", "application/x-www-form-urlencoded")],
    body="name=%E6%97%A5+x&tag=a&tag=b",
  )
  let f = r.form()
  assert_eq(f.values.pairs, [("name", "日 x"), ("tag", "a"), ("tag", "b")])
  assert_eq(f.files.length(), 0)
  let r = request("POST", "/", headers=[("content-type", "text/plain")])
  assert_true(raises(() => ignore(r.form())))
}

///|
test "Request::form multipart" {
  let body =
    #|preamble
    #|--XyZ
    #|Content-Disposition: form-data; name="title"
    #|
    #|日本語
    #|--XyZ
    #|Content-Disposition: form-data; name="file"; filename="a.txt"
    #|Content-Type: text/plain
    #|
    #|line 1
    #|line 2
    #|--XyZ
    #|Content-Disposition: form-data; name="empty"
    #|
    #|
    #|--XyZ--
    #|epilogue
  let r = request(
    "POST",
    "/",
    headers=[("content-type", "multipart/form-data; boundary=XyZ")],
    body=body.replace_all(old="\n", new="\r\n"),
  )
  let f = r.form()
  assert_eq(f.values.pairs, [("title", "日本語"), ("empty", "")])
  assert_eq(f.files.length(), 1)
  let file = f.files[0]
  assert_eq(
    (file.name, file.filename, file.content_type),
    ("file", "a.txt", "text/plain"),
  )
  assert_eq(@utf8.decode_lossy(file.data), "line 1\r\nline 2")
  let r = request(
    "POST",
    "/",
    headers=[("content-type", "multipart/form-data; boundary=XyZ")],
    body="--XyZ\r\nContent-Disposition: form-data; name=\"a\"\r\n\r\nno end",
  )
  assert_true(raises(() => ignore(r.form())))
  let r = request("POST", "/", headers=[("content-type", "multipart/form-data")])
  assert_true(raises(() => ignore(r.form())))
}

///|
fn router() -> @http.Router {
  let r = @http.Router()
  let says = (name : String) => {
    (req : @http.Request) => {
      @http.Response::text(
        200,
        "\{name} \{req.params.to_array().map(p => "\{p.0}=\{p.1}").join(",")}",
      )
    }
  }
  r.handle("/", says("root"))
  r.handle("GET /{$}", says("home"))
  r.handle("GET /posts/{slug}", says("post"))
  r.handle("GET /posts/new", says("new"))
  r.handle("POST /posts/{slug}", says("update"))
  r.handle("/docs/", says("docs"))
  r.handle("GET /docs/{$}", says("docs-index"))
  r.handle("GET /files/{path...}", says("files"))
  r.handle("DELETE /items/{id}", says("delete"))
  r
}

///|
test "Router" {
  let r = router()
  let get = (verb : String, url : String) => {
    let res = r.serve(request(verb, url))
    (res.status, body_text(res))
  }
  assert_eq(get("GET", "/"), (200, "home "))
  assert_eq(get("POST", "/"), (200, "root "))
  assert_eq(get("GET", "/nothing"), (200, "root "))
  assert_eq(get("GET", "/posts/hello"), (200, "post slug=hello"))
  assert_eq(get("HEAD", "/posts/hello"), (200, "post slug=hello"))
  assert_eq(get("GET", "/posts/new"), (200, "new "))
  assert_eq(get("POST", "/posts/new"), (200, "update slug=new"))
  assert_eq(get("GET", "/posts/a%2Fb"), (200, "post slug=a/b"))
  assert_eq(get("GET", "/posts/a/b"), (200, "root "))
  assert_eq(get("GET", "/docs/"), (200, "docs-index "))
  assert_eq(get("POST", "/docs/"), (200, "docs "))
  assert_eq(get("GET", "/docs/a/b"), (200, "docs "))
  assert_eq(get("GET", "/files/"), (200, "files path="))
  assert_eq(get("GET", "/files/a/%E6%97%A5"), (200, "files path=a/日"))
}

///|
test "Router with decoded_path" {
  let r = @http.Router(decoded_path=true)
  r.handle("GET /posts/{slug}", req => {
    @http.Response::text(200, req.param("slug"))
  })
  r.handle("GET /docs/{$}", _ => @http.Response::text(200, "docs"))
  assert_eq(r.serve(request("GET", "/posts/a%2Fb")).status, 404)
  assert_eq(body_text(r.serve(request("GET", "/posts/a%20b"))), "a b")
  assert_eq(body_text(r.serve(request("GET", "/docs%2F"))), "docs")
}

///|
test "Router without a catch-all" {
  let r = @http.Router()
  r.handle("GET /items/{id}", req => @http.Response::text(200, req.param("id")))
  r.handle("DELETE /items/{id}", _ => @http.Response(204))
  let res = r.serve(request("GET", "/items/7"))
  assert_eq((res.status, body_text(res)), (200, "7"))
  let res = r.serve(request("PUT", "/items/7"))
  assert_eq(res.status, 405)
  assert_eq(res.headers.get("allow"), Some("GET, HEAD, DELETE"))
  let res = r.serve(request("GET", "/items/"))
  assert_eq(res.status, 404)
  let r = @http.Router(not_found=_ => @http.Response::text(404, "custom"))
  assert_eq(body_text(r.serve(request("GET", "/"))), "custom")
}
