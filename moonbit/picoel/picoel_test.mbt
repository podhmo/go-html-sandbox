// Ported from go/pkg/picoel/picoel_test.go. The Script case is left out
// with Script itself, and Date takes the YYYY-MM-DD string.

///|
test "document" {
  let got = @el.render_html(
    @picoel.document("en", head=[@picoel.title("T")], [
      @picoel.main_([@picoel.p([@picoel.text("x")])]),
    ]),
  )
  let want = [
    "<html lang=\"en\" data-theme=\"dark\"><head>",
    "<meta charset=\"utf-8\">",
    "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">",
    "<meta name=\"color-scheme\" content=\"dark\">",
    "<link rel=\"stylesheet\" href=\"\{@picoel.STYLESHEET_URL}\">",
    "<title>T</title>",
    "</head><body><main class=\"container\"><p>x</p></main></body></html>",
  ].join("")
  assert_eq(got, want)
}

///|
test "elements" {
  let t = @picoel.text
  let cases : Array[(@el.Node, String)] = [
    (@picoel.header([t("h")]), "<header class=\"container\">h</header>"),
    (@picoel.footer([t("f")]), "<footer class=\"container\">f</footer>"),
    (@picoel.inner_header([t("h")]), "<header>h</header>"),
    (
      @picoel.nav([@picoel.a("/", [@picoel.strong([t("s")])])]),
      "<nav><ul><li><a href=\"/\"><strong>s</strong></a></li></ul></nav>",
    ),
    (
      @picoel.list([
        @picoel.li([t("a")]),
        @picoel.li([t("b"), @picoel.code("c")]),
      ]),
      "<ul><li>a</li><li>b<code>c</code></li></ul>",
    ),
    (
      @picoel.article([
        @picoel.hgroup([
          @picoel.h2([t("t")]),
          @picoel.p([@picoel.date("2026-10-14")]),
        ]),
      ]),
      "<article><hgroup><h2>t</h2><p><time datetime=\"2026-10-14\">2026-10-14</time></p></hgroup></article>",
    ),
    (
      @picoel.section([@picoel.h1([t("a")]), @picoel.h3([t("b")])]),
      "<section><h1>a</h1><h3>b</h3></section>",
    ),
    (
      @picoel.blockquote([@picoel.p([t("q")])]),
      "<blockquote><p>q</p></blockquote>",
    ),
    (@picoel.pre("x := <1>"), "<pre>x := &lt;1&gt;</pre>"),
    (
      @picoel.section([@picoel.h4([t("d")]), @picoel.h5([t("e")])]),
      "<section><h4>d</h4><h5>e</h5></section>",
    ),
    (
      @picoel.table([[t("a")], [@picoel.code("b")]], [[[t("1")], []]]),
      "<div class=\"overflow-auto\"><table><thead><tr><th>a</th><th><code>b</code></th></tr></thead><tbody><tr><td>1</td><td></td></tr></tbody></table></div>",
    ),
    (
      @picoel.table([[t("a")]], []),
      "<div class=\"overflow-auto\"><table><thead><tr><th>a</th></tr></thead></table></div>",
    ),
    (
      @picoel.p([t("run "), @picoel.code("a<b")]),
      "<p>run <code>a&lt;b</code></p>",
    ),
    (@picoel.small([t("<s>")]), "<small>&lt;s&gt;</small>"),
    (@picoel.a("/?a=\"b\"", [t("x")]), "<a href=\"/?a=&#34;b&#34;\">x</a>"),
    (
      @picoel.download_link("/a.md", filename="\"a\".md", [t("x")]),
      "<a href=\"/a.md\" download=\"&#34;a&#34;.md\" class=\"secondary\">x</a>",
    ),
    (
      @picoel.spread([t("a")], end=[t("b"), t("c")]),
      "<nav><ul><li>a</li></ul><ul><li>b</li><li>c</li></ul></nav>",
    ),
    (
      @picoel.meta_property("og:title", content="t"),
      "<meta property=\"og:title\" content=\"t\">",
    ),
    (
      @picoel.stylesheet("/a.css?v=1"),
      "<link rel=\"stylesheet\" href=\"/a.css?v=1\">",
    ),
    (
      @picoel.icon("/favicon.svg", mime_type="image/svg+xml"),
      "<link rel=\"icon\" href=\"/favicon.svg\" type=\"image/svg+xml\">",
    ),
    (@picoel.meta_name("a", content="b"), "<meta name=\"a\" content=\"b\">"),
  ]
  for (node, want) in cases {
    assert_eq(@el.render_html(node), want)
  }
}
