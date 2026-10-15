// Ported from the Go blog's posts_test.go and server_test.go, for the
// routes served so far: / and /posts/{slug}.

///|
let test_docs : ReadOnlyArray[(String, String)] = [
  ("TODO.md", "# TODO\n\n> note\n\n- [ ] **task**: first line\n  second line"),
  (
    "docs/ja/design.md", "# Design <x>\n\nwhy\n## Use `el`\n- run `go test`\n- ``a ` b``",
  ),
  ("docs/notes.md", "no heading"),
  ("docs/image.svg", "<svg/>"),
]

///|
let test_posts : ReadOnlyArray[(String, String)] = [
  ("2026-10-01-old.md", "# Old post\nold body"),
  (
    "2026-10-14-hello.md", "# Hello <script>\n\nfirst\n## Points\n- one\n- two\n```\nx := <1>\n```",
  ),
]

///|
fn new_site(
  posts : ReadOnlyArray[(String, String)],
) -> @site.Site raise @site.LoadError {
  @site.Site::new(
    base_url="https://example.com",
    posts=@site.load_posts(posts),
    docs=@site.load_docs(test_docs),
  )
}

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
/// body returns the body of what s answers for path, failing unless the
/// status is want.
fn body(s : @site.Site, path : String, want~ : Int32 = 200) -> String raise {
  let res = s.render(path)
  assert_eq(res.status, want, msg="status of \{path}")
  res.body
}

///|
fn assert_contains(body : String, wants : Array[String]) -> Unit raise {
  for want in wants {
    assert_true(body.contains(want), msg="body does not contain \{want}")
  }
}

///|
test "load posts" {
  let posts = @site.load_posts([
    ("2026-10-01-old.md", "# Old\nbody"),
    ("2026-10-14-hello.md", "intro\n# Hello\n## Sub\n# Second"),
    ("2026-10-14-another.md", "# Another"),
    ("README.txt", "ignored: not *.md"),
  ])
  assert_eq([ for p in posts => "\{p.date} \{p.slug} \{p.title}" ], [
    "2026-10-14 another Another", "2026-10-14 hello Hello", "2026-10-01 old Old",
  ])
}

///|
test "load posts errors" {
  let cases : Array[(String, ReadOnlyArray[(String, String)], String)] = [
    ("no date", [("hello.md", "# x")], "YYYY-MM-DD-slug.md"),
    ("no slug", [("2026-10-14.md", "# x")], "YYYY-MM-DD-slug.md"),
    ("uppercase slug", [("2026-10-14-Hello.md", "# x")], "YYYY-MM-DD-slug.md"),
    ("double dash", [("2026-10-14-a--b.md", "# x")], "YYYY-MM-DD-slug.md"),
    ("trailing dash", [("2026-10-14-a-.md", "# x")], "YYYY-MM-DD-slug.md"),
    ("invalid date", [("2026-13-01-x.md", "# x")], "month out of range"),
    ("invalid day", [("2026-02-29-x.md", "# x")], "day out of range"),
    (
      "duplicate slug",
      [("2026-10-01-same.md", "# a"), ("2026-10-14-same.md", "# b")],
      "slug \"same\" is already used",
    ),
    ("no title", [("2026-10-14-x.md", "## only h2")], "no title"),
    (
      "bad front matter",
      [("2026-10-14-x.md", "---\ntitle: x\n")],
      "2026-10-14-x.md: tinyfrontmatter: no closing",
    ),
    (
      "unknown front matter key",
      [("2026-10-14-x.md", "---\ntitel: x\n---\n# x")],
      "unknown front matter key \"titel\"",
    ),
  ]
  for c in cases {
    let (name, files, want) = c
    let msg = try @site.load_posts(files) catch {
      LoadError(msg) => msg
    } noraise {
      _ => fail("\{name}: want an error")
    }
    assert_true(msg.contains(want), msg="\{name}: got \{msg}, want \{want}")
  }
}

///|
test "a leap day is a date" {
  let posts = @site.load_posts([("2028-02-29-leap.md", "# Leap")])
  assert_eq(posts[0].date, "2028-02-29")
}

///|
test "load posts front matter" {
  let cases = [
    ("from body", "intro\n# Heading\nfirst\nline\n\nsecond", "Heading", "intro"),
    (
      "paragraph inside a section", "# Heading\n## Sub\n- list\n\nnested\nline",
      "Heading", "nested line",
    ),
    ("no paragraph", "# Heading\n- only a list", "Heading", ""),
    (
      "front matter wins", "---\ntitle: FM title\ndescription: FM desc\n---\n# Heading\nbody",
      "FM title", "FM desc",
    ),
    (
      "front matter title without heading", "---\ntitle: Only FM\n---\nbody", "Only FM",
      "body",
    ),
    (
      "empty values fall back", "---\ntitle:\ndescription:\n---\n# Heading\nbody",
      "Heading", "body",
    ),
  ]
  for c in cases {
    let (name, src, title, description) = c
    let p = @site.load_posts([("2026-10-14-x.md", src)])[0]
    assert_eq((p.title, p.description), (title, description), msg=name)
  }
}

///|
test "list" {
  let res = new_site(test_posts).render("/")
  assert_eq(res.status, 200)
  assert_eq(header(res, "content-type"), Some("text/html; charset=utf-8"))
  assert_true(res.body.has_prefix("<!doctype html>\n"))
  let hello = res.body.find("<a href=\"/posts/hello\">")
  let old = res.body.find("<a href=\"/posts/old\">")
  guard hello is Some(hello) && old is Some(old) && hello < old else {
    fail("want links to hello then old")
  }
  assert_false(res.body.contains("<script>"), msg="title must be escaped")
}

///|
test "pico only" {
  let body = body(new_site(test_posts), "/posts/hello")
  let pico = body.find(
    "<link rel=\"stylesheet\" href=\"\{@picoel.STYLESHEET_URL}\">",
  )
  let site = body.find("<link rel=\"stylesheet\" href=\"/site.css?v=")
  guard pico is Some(pico) && site is Some(site) && pico < site else {
    fail("want pico, then site.css")
  }
  assert_eq(body.split("rel=\"stylesheet\"").count() - 1, 2)
  assert_false(body.contains("<style") || body.contains(" style="))
  assert_contains(body, [
    "<header class=\"container\">", "<main class=\"container\">", "<footer class=\"container\">",
  ])
}

///|
test "post" {
  assert_contains(body(new_site(test_posts), "/posts/hello"), [
    "<title>Hello &lt;script&gt; - blog</title>", "<time datetime=\"2026-10-14\">2026-10-14</time>",
    "<section><h1>Hello &lt;script&gt;</h1><p>first</p><section><h2>Points</h2><ul><li>one</li><li>two</li></ul><pre>x := &lt;1&gt;</pre></section></section>",
  ])
}

///|
test "not found pages" {
  let s = new_site(test_posts)
  assert_contains(body(s, "/posts/nope", want=404), [
    "<title>404 Not Found - blog</title>", "<h1>404 Not Found</h1><p>Post not found.</p>",
    "<a href=\"/\">Back to all posts</a>",
  ])
  assert_contains(body(s, "/nope", want=404), ["<p>Page not found.</p>"])
  assert_contains(body(s, "/a<b>&\"c'", want=404), ["<p>Page not found.</p>"])
}

///|
test "post page heading" {
  let s = new_site([
    (
      "2026-10-14-fm.md", "---\ntitle: From <FM>\ndescription: Short & sweet\n---\nbody",
    ),
    ("2026-10-14-both.md", "---\ntitle: FM title\n---\n# Body heading\nbody"),
  ])
  assert_contains(body(s, "/posts/fm"), [
    "<title>From &lt;FM&gt; - blog</title>", "<meta name=\"description\" content=\"Short &amp; sweet\">",
    "<h1>From &lt;FM&gt;</h1><p>body</p>",
  ])
  let both = body(s, "/posts/both")
  assert_contains(both, [
    "<title>FM title - blog</title>", "<h1>Body heading</h1>",
  ])
  assert_eq(both.split("<h1>").count() - 1, 1)
}

///|
test "ogp" {
  let s = new_site([
    (
      "2026-10-14-hello.md", "---\ndescription: Say \"hi\" & more\n---\n# Hello\nbody",
    ),
  ])
  assert_contains(body(s, "/"), [
    "<title>blog</title>", "<meta property=\"og:title\" content=\"blog\">", "<meta property=\"og:type\" content=\"website\">",
    "<meta property=\"og:url\" content=\"https://example.com/\">", "<meta property=\"og:description\" content=\"Notes rendered with the Go standard library only.\">",
    "<meta property=\"og:site_name\" content=\"blog\">",
  ])
  assert_contains(body(s, "/posts/hello"), [
    "<meta property=\"og:title\" content=\"Hello\">", "<meta property=\"og:type\" content=\"article\">",
    "<meta property=\"og:url\" content=\"https://example.com/posts/hello\">", "<meta property=\"og:description\" content=\"Say &#34;hi&#34; &amp; more\">",
  ])
  assert_false(body(s, "/nope", want=404).contains("og:"))
}

///|
test "base url" {
  let posts = @site.load_posts([("2026-10-14-x.md", "# x")])
  let cases = [
    ("https://example.com", "https://example.com/posts/x"),
    ("https://example.com/", "https://example.com/posts/x"),
    ("https://example.com/blog/", ""),
    ("http://localhost:8080", "http://localhost:8080/posts/x"),
    ("example.com", ""),
    ("ftp://example.com", ""),
    ("https://example.com/?q=1", ""),
    ("", ""),
  ]
  for c in cases {
    let (base_url, want) = c
    let s = @site.Site::new(base_url~, posts~, docs=[]) catch {
      LoadError(_) => {
        assert_eq(want, "", msg="\{base_url}: want no error")
        continue
      }
    }
    assert_true(want != "", msg="\{base_url}: want an error")
    assert_contains(body(s, "/posts/x"), [
      "<meta property=\"og:url\" content=\"\{want}\">",
    ])
  }
}

///|
test "tables and deep headings" {
  let s = new_site([
    (
      "2026-10-14-hello.md", "# Hello\n#### Four\n##### Five\n| a | `b` |\n| --- | --- |\n| [x](#x) | <i> |",
    ),
  ])
  assert_contains(body(s, "/posts/hello"), [
    [
      "<section><h4>Four</h4><section><h5>Five</h5>", "<div class=\"overflow-auto\"><table><thead><tr><th>a</th><th><code>b</code></th></tr></thead>",
      "<tbody><tr><td><a href=\"#x\">x</a></td><td>&lt;i&gt;</td></tr></tbody></table></div></section></section>",
    ].join(""),
  ])
}

///|
test "markdown in titles" {
  let s = new_site([
    (
      "2026-10-14-t.md", "# Put `x` on [Workers](https://example.com/)\nUse `go` and [docs](https://example.com/docs).",
    ),
    ("2026-10-13-fm.md", "---\ntitle: Run `go test`\n---\nbody"),
  ])
  assert_contains(body(s, "/"), [
    "<a href=\"/posts/t\">Put <code>x</code> on Workers</a>", "<a href=\"/posts/fm\">Run <code>go test</code></a>",
  ])
  assert_contains(body(s, "/posts/t"), [
    "<title>Put x on Workers - blog</title>", "<meta property=\"og:title\" content=\"Put x on Workers\">",
    "<meta name=\"description\" content=\"Use go and docs.\">",
  ])
  assert_contains(body(s, "/posts/fm"), [
    "<title>Run go test - blog</title>", "<h1>Run <code>go test</code></h1>",
  ])
}

///|
test "links in pages" {
  let s = new_site([
    (
      "2026-10-14-hello.md", "# Hello [`x`](https://x.test)\n\n- [design](../../../../docs/ja/design.md)\n\n[bad](javascript:alert(1)) [ok](#a)",
    ),
  ])
  assert_contains(body(s, "/posts/hello"), [
    "<h1>Hello <a href=\"https://x.test\"><code>x</code></a></h1>", "<li><a href=\"/docs/ja/design\">design</a></li>",
    // The URL holds "(" so this is no link at all.
     "<p>[bad](javascript:alert(1)) <a href=\"#a\">ok</a></p>",
  ])
  let s = new_site([
    (
      "2026-10-14-hello.md", "# Hello\n\n[bad](javascript:alert) and [up](../../../../../x)",
    ),
  ])
  assert_contains(body(s, "/posts/hello"), ["<p>bad and up</p>"])
}

///|
test "the embedded posts and documents load" {
  let s = @site.Site::embedded(base_url="https://example.com")
  assert_contains(body(s, "/"), ["<a href=\"/posts/hello\">"])
  assert_contains(body(s, "/posts/hello"), ["<h1>Hello</h1>"])
}
