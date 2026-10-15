///|
fn html(status : Int32, body : String) -> Result[@compare.Fetched, String] {
  Ok({ status, content_type: "text/html; charset=utf-8", body, })
}

///|
test "default paths cover the routes the step asks for" {
  assert_eq(@compare.default_paths(), [
    "/", "/posts/hello", "/docs/ja/design", "/docs/", "/favicon.svg", "/no-such-page",
  ])
}

///|
test "join_url drops the slashes at the end of the base" {
  assert_eq(
    @compare.join_url("http://localhost:8080", path="/a"),
    "http://localhost:8080/a",
  )
  assert_eq(
    @compare.join_url("http://localhost:8080//", path="/a"),
    "http://localhost:8080/a",
  )
}

///|
test "same responses" {
  let r = @compare.compare(
    "/",
    go=html(200, "<p>x</p>"),
    moonbit=html(200, "<p>x</p>"),
  )
  assert_true(r.same)
  assert_eq(r.text, "/: same\n")
}

///|
test "every part that differs is named" {
  let r = @compare.compare(
    "/favicon.svg",
    go=Ok({ status: 200, content_type: "image/svg+xml", body: "<svg></svg>", }),
    moonbit=html(404, "<h1>Not found</h1>"),
  )
  assert_false(r.same)
  assert_eq(
    r.text,
    (
      #|/favicon.svg: differs (status, content-type, body)
      #|  status: go 200, moonbit 404
      #|  content-type: go "image/svg+xml", moonbit "text/html; charset=utf-8"
      #|  body: go 11 chars, moonbit 18 chars
      #|    --- go
      #|    +++ moonbit
      #|    @@ -1,2 +1,2 @@
      #|    -<svg>
      #|    -</svg>
      #|    +<h1>
      #|    +Not found</h1>
      #|
    ),
  )
}

///|
test "the body diff splits after '>' and newlines, and keeps context" {
  let go = "<ul>\n<li>a</li><li>b</li><li>c</li><li>d</li></ul>"
  let moonbit = "<ul>\n<li>a</li><li>B</li><li>c</li><li>d</li></ul>"
  assert_eq(
    @compare.body_diff(go, moonbit~),
    (
      #|--- go
      #|+++ moonbit
      #|@@ -4,5 +4,5 @@
      #| a</li>
      #| <li>
      #|-b</li>
      #|+B</li>
      #| <li>
      #| c</li>
      #|
    ),
  )
}

///|
test "the body diff is cut after max_lines" {
  let out = @compare.body_diff("a\nb\nc\n", moonbit="x\ny\nz\n", max_lines=3)
  assert_eq(
    out,
    (
      #|--- go
      #|+++ moonbit
      #|@@ -1,3 +1,3 @@
      #|-a\n
      #|-b\n
      #|... 4 more lines
      #|
    ),
  )
}

///|
test "a failed fetch is reported as an error" {
  let r = @compare.compare(
    "/",
    go=Err("connection refused"),
    moonbit=html(200, ""),
  )
  assert_false(r.same)
  assert_eq(r.text, "/: error\n  go: connection refused\n")
}

///|
test "summary counts the paths that differ" {
  let reports = [
    @compare.compare("/", go=html(200, "a"), moonbit=html(200, "a")),
    @compare.compare("/x", go=html(200, "a"), moonbit=html(404, "a")),
  ]
  assert_eq(@compare.summary(reports), "1 of 2 paths differ\n")
}
