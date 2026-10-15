// Ported from go/pkg/el/node_test.go and render_test.go. The Go cases for
// a nil child, an unknown node type, and a failing writer have no
// counterpart: Node is a closed enum without nil, and the output is a
// StringBuilder, which cannot fail.

///|
test "constructors" {
  assert_eq(@el.Text("hi"), @el.Text("hi"))
  assert_eq(@el.Raw("<b>"), @el.Raw("<b>"))
  assert_eq(@el.Attr(@el.class, "x"), @el.Attr(@el.AttrName("class"), "x"))
  assert_eq(
    @el.BoolAttr(@el.AttrName("hidden")),
    @el.BoolAttr(@el.AttrName("hidden")),
  )
  assert_eq(@el.el(@el.br, []), @el.Element(@el.Tag("br"), []))
  assert_eq(
    @el.el(@el.div, [@el.Attr(@el.id, "a"), @el.el(@el.p, [@el.Text("hi")])]),
    @el.Element(@el.Tag("div"), [
      @el.Attr(@el.AttrName("id"), "a"),
      @el.Element(@el.Tag("p"), [@el.Text("hi")]),
    ]),
  )
  assert_eq(
    @el.el(@el.Tag("my-widget"), [@el.Attr(@el.AttrName("data-id"), "1")]),
    @el.Element(@el.Tag("my-widget"), [@el.Attr(@el.AttrName("data-id"), "1")]),
  )
}

///|
test "leaf nodes are comparable" {
  let s = "a"
  assert_true(@el.Text(s) == @el.Text("a"))
  let href = "/"
  assert_true(@el.Attr(@el.href, href) == @el.Attr(@el.AttrName("href"), "/"))
}

///|
test "html renderer" {
  let cases : Array[(String, @el.Node, String)] = [
    ("text", @el.Text("hello"), "hello"),
    (
      "text is escaped",
      @el.Text("<script>alert(\"x\")</script>"),
      "&lt;script&gt;alert(&#34;x&#34;)&lt;/script&gt;",
    ),
    ("raw is not escaped", @el.Raw("<!doctype html>"), "<!doctype html>"),
    ("empty element", @el.el(@el.p, []), "<p></p>"),
    (
      "nested",
      @el.el(@el.ul, [
        @el.el(@el.li, [@el.Text("a")]),
        @el.el(@el.li, [@el.Text("b")]),
      ]),
      "<ul><li>a</li><li>b</li></ul>",
    ),
    (
      "attributes go into the start tag",
      @el.el(@el.a, [
        @el.Text("top"),
        @el.Attr(@el.href, "/"),
        @el.Attr(@el.class, "x"),
      ]),
      "<a href=\"/\" class=\"x\">top</a>",
    ),
    (
      "attribute value is escaped",
      @el.el(@el.a, [@el.Attr(@el.href, "/\" onclick=\"x")]),
      "<a href=\"/&#34; onclick=&#34;x\"></a>",
    ),
    (
      "bool attribute",
      @el.el(@el.input, [@el.BoolAttr(@el.AttrName("hidden"))]),
      "<input hidden>",
    ),
    (
      "void element drops content",
      @el.el(@el.br, [@el.Text("ignored")]),
      "<br>",
    ),
    (
      "void element with attrs",
      @el.el(@el.meta, [@el.Attr(@el.charset, "utf-8")]),
      "<meta charset=\"utf-8\">",
    ),
  ]
  for (name, node, want) in cases {
    assert_eq(@el.render_html(node), want, msg=name)
  }
}

///|
test "plain renderer" {
  let cases : Array[(String, @el.Node, String)] = [
    ("text is not escaped", @el.Text("a < b & c"), "a < b & c"),
    ("raw is dropped", @el.el(@el.style, [@el.Raw("p{color:red}")]), ""),
    (
      "tags and attributes are dropped",
      @el.el(@el.span, [
        @el.Attr(@el.class, "x"),
        @el.BoolAttr(@el.AttrName("hidden")),
        @el.Text("one "),
        @el.el(@el.a, [@el.Attr(@el.href, "/"), @el.Text("two")]),
      ]),
      "one two",
    ),
    (
      "block elements go on their own lines",
      @el.el(@el.div, [
        @el.el(@el.h1, [@el.Text("Title")]),
        @el.el(@el.p, [@el.Text("a "), @el.el(@el.a, [@el.Text("link")])]),
        @el.el(@el.p, [@el.Text("b")]),
      ]),
      "Title\na link\nb\n",
    ),
    (
      "nested blocks do not make blank lines",
      @el.el(@el.section, [
        @el.el(@el.section, [
          @el.el(@el.ul, [
            @el.el(@el.li, [@el.Text("x")]),
            @el.el(@el.li, [@el.Text("y")]),
          ]),
        ]),
      ]),
      "x\ny\n",
    ),
    (
      "text around a block",
      @el.el(@el.span, [
        @el.Text("before"),
        @el.el(@el.p, [@el.Text("in")]),
        @el.Text("after"),
      ]),
      "before\nin\nafter",
    ),
    (
      "pre keeps its newlines",
      @el.el(@el.pre, [@el.Text("a\n  b")]),
      "a\n  b\n",
    ),
    (
      "br breaks a line",
      @el.el(@el.p, [@el.Text("a"), @el.el(@el.br, []), @el.Text("b")]),
      "a\nb\n",
    ),
    (
      "empty blocks write nothing",
      @el.el(@el.div, [@el.el(@el.p, []), @el.el(@el.p, [])]),
      "",
    ),
  ]
  for (name, node, want) in cases {
    assert_eq(@el.render_plain(node), want, msg=name)
  }
}

///|
test "escaping matches Go's html.EscapeString" {
  assert_eq(@el.render_html(@el.Text("<>&'\"")), "&lt;&gt;&amp;&#39;&#34;")
  assert_eq(@el.render_html(@el.Text("日本語")), "日本語")
}
