///|
fn header(res : @site.Response, name : String) -> String? {
  for h in res.headers {
    if h.0 == name {
      return Some(h.1)
    }
  }
  None
}

///|
test "top page" {
  let res = @site.render("/")
  assert_eq(res.status, 200)
  assert_eq(header(res, "content-type"), Some("text/html; charset=utf-8"))
  assert_true(res.body.has_prefix("<!doctype html>\n"))
  assert_true(res.body.contains("<title>blog</title>"))
  assert_true(res.body.contains("<h1>blog</h1>"))
}

///|
test "not found page escapes the path" {
  let res = @site.render("/a<b>&\"c'")
  assert_eq(res.status, 404)
  assert_eq(header(res, "content-type"), Some("text/html; charset=utf-8"))
  assert_true(res.body.contains("<title>Not found | blog</title>"))
  assert_true(res.body.contains("<code>/a&lt;b&gt;&amp;&#34;c&#39;</code>"))
}
