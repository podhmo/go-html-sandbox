// Ported from the Go blog's links_test.go and server_test.go: the parts
// that reach into the site's internals.

///|
test "linker" {
  let s = Site(
    base_url="https://example.com",
    posts=load_posts([
      ("2026-10-01-old.md", "# Old post\nold body"),
      ("2026-10-14-hello.md", "# Hello"),
    ]),
    docs=load_docs([
      ("TODO.md", "# TODO"),
      ("docs/ja/design.md", "# Design"),
      ("docs/notes.md", "no heading"),
    ]),
  )
  let gh = "https://github.com/podhmo/html-sandbox/blob/main/"
  let hello = "go/examples/blog/posts/2026-10-14-hello.md"
  let cases = [
    ("TODO.md", "https://example.com/a?b#c", "https://example.com/a?b#c"),
    ("TODO.md", "HTTP://example.com", "HTTP://example.com"),
    ("TODO.md", "mailto:a@example.com", "mailto:a@example.com"),
    ("TODO.md", "javascript:alert(1)", ""),
    ("TODO.md", "JavaScript:alert(1)", ""),
    ("TODO.md", "data:text/html,x", ""),
    ("TODO.md", "//example.com/x", "//example.com/x"),
    ("TODO.md", "/posts/hello", "/posts/hello"),
    ("TODO.md", "#to-be-implemented", "#to-be-implemented"),
    ("TODO.md", "docs/ja/design.md", "/docs/ja/design"),
    ("TODO.md", "./docs/ja/design.md#why", "/docs/ja/design#why"),
    ("docs/ja/design.md", "../../TODO.md", "/docs/TODO"),
    ("docs/ja/design.md", "../notes.md", "/docs/notes"),
    ("TODO.md", "go/examples/blog/posts/2026-10-01-old.md", "/posts/old"),
    (hello, "2026-10-01-old.md", "/posts/old"),
    (hello, "../../../../docs/ja/design.md", "/docs/ja/design"),
    (
      "TODO.md",
      ".claude/skills/todo-md/SKILL.md",
      "\{gh}.claude/skills/todo-md/SKILL.md",
    ),
    ("TODO.md", "go/pkg/el/el.go#L10", "\{gh}go/pkg/el/el.go#L10"),
    ("docs/ja/design.md", "../../go/pkg/", "\{gh}go/pkg"),
    ("TODO.md", "a b.md", "\{gh}a%20b.md"),
    ("TODO.md", "../outside.md", ""),
    ("docs/ja/design.md", "../../../x", ""),
    // Beyond the Go cases: escapes, queries, and URLs url.Parse rejects.
    ("TODO.md", "a%20b.md?x=1#y z", "\{gh}a%20b.md?x=1#y%20z"),
    (
      "TODO.md",
      "メモ.md#見出し",
      "\{gh}%E3%83%A1%E3%83%A2.md#%E8%A6%8B%E5%87%BA%E3%81%97",
    ),
    ("TODO.md", "docs/ja/design.md?x=1", "/docs/ja/design"),
    ("TODO.md", "a%2.md", ""),
    ("TODO.md", "1a:b", ""),
    ("TODO.md", ":x", ""),
    ("TODO.md", "a\u{7F}b", ""),
  ]
  for (source, url, want) in cases {
    let got = s.linker(source)(url).unwrap_or("")
    assert_eq(got, want, msg="\{source}: link \{url}")
  }
}

///|
test "post page text" {
  let posts = load_posts([
    ("2026-10-01-old.md", "# Old post\nold body"),
    (
      "2026-10-14-hello.md",
      (
        #|# Hello <script>
        #|
        #|first
        #|## Points
        #|- one
        #|  - one.1
        #|- two
        #|```
        #|x := <1>
        #|```
      ),
    ),
  ])
  let s = Site(base_url="https://example.com", posts~, docs=[])
  let got = @el.render_plain(s.post_page(posts[0]))
  assert_eq(
    got,
    (
      #|Hello <script> - blog
      #|blog
      #|docs
      #|github
      #|2026-10-14
      #|Download .md
      #|Hello <script>
      #|first
      #|Points
      #|one
      #|one.1
      #|two
      #|x := <1>
      #|Rendered with Wasm.
      #|
    ),
  )
}

///|
test "load docs" {
  let docs = load_docs([
    ("TODO.md", "# TODO\n\n> note"),
    ("docs/ja/design.md", "# Design <x>\n\nwhy"),
    ("docs/ja-old.md", "old"),
    ("docs/notes.md", "no heading"),
    ("docs/image.svg", "<svg/>"),
    ("README.md", "# not a doc"),
  ])
  assert_eq([ for d in docs => (d.path, d.source, d.title, d.description) ], [
    ("TODO", "TODO.md", "TODO", ""),
    ("ja/design", "docs/ja/design.md", "Design <x>", "why"),
    ("ja-old", "docs/ja-old.md", "docs/ja-old.md", "old"),
    ("notes", "docs/notes.md", "docs/notes.md", "no heading"),
  ])
}
