///|
test "top page" {
  let html = @site.render("/")
  assert_true(html.has_prefix("<!doctype html>\n"))
  assert_true(html.contains("<title>blog</title>"))
  assert_true(html.contains("<h1>blog</h1>"))
}

///|
test "not found page escapes the path" {
  let html = @site.render("/a<b>&\"c'")
  assert_true(html.contains("<title>Not found | blog</title>"))
  assert_true(html.contains("<code>/a&lt;b&gt;&amp;&quot;c&#39;</code>"))
}
