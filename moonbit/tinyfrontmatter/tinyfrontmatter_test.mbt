// Ported from go/pkg/tinyfrontmatter/tinyfrontmatter_test.go. Go's nil map
// is None here, and an empty map is Some of an empty Map.

///|
fn meta(pairs : Array[(String, String)]) -> Map[String, String]? {
  Some(Map::from_array(pairs))
}

///|
test "split" {
  let cases : Array[(String, String, Map[String, String]?, String)] = [
    ("no front matter", "# Title\nbody", None, "# Title\nbody"),
    ("empty document", "", None, ""),
    (
      "--- not on the first line",
      "\n---\na: b\n---\n",
      None,
      "\n---\na: b\n---\n",
    ),
    (
      "front matter",
      "---\ntitle: Hello\ndescription: A short post.\n---\n# Hello\n",
      meta([("title", "Hello"), ("description", "A short post.")]),
      "# Hello\n",
    ),
    ("empty front matter", "---\n---\nbody", meta([]), "body"),
    ("closing at EOF without newline", "---\na: b\n---", meta([("a", "b")]), ""),
    (
      "blank lines are skipped",
      "---\n\na: b\n  \n---\n",
      meta([("a", "b")]),
      "",
    ),
    (
      "value keeps later colons",
      "---\ntitle: Go: the basics\n---\n",
      meta([("title", "Go: the basics")]),
      "",
    ),
    (
      "spaces are trimmed",
      "---  \n  key  :   value  \n---\t\n",
      meta([("key", "value")]),
      "",
    ),
    (
      "surrounding quotes are removed",
      "---\na: \"x: y\"\nb: 'z'\nc: \"mismatch'\nd: \"\n---\n",
      meta([("a", "x: y"), ("b", "z"), ("c", "\"mismatch'"), ("d", "\"")]),
      "",
    ),
    ("empty value", "---\na:\n---\n", meta([("a", "")]), ""),
    (
      "CRLF",
      "---\r\ntitle: Hello\r\n---\r\nbody\r\n",
      meta([("title", "Hello")]),
      "body\r\n",
    ),
  ]
  for (name, src, want_meta, want_body) in cases {
    let (got_meta, got_body) = @tinyfrontmatter.split(src) catch {
      SplitError(msg) => fail("\{name}: \{msg}")
    }
    assert_eq(got_meta, want_meta, msg="\{name}: meta")
    assert_eq(got_body, want_body, msg="\{name}: body")
  }
}

///|
test "keys keep the order they appear in" {
  let (got, _) = @tinyfrontmatter.split("---\nb: 1\na: 2\n---\n")
  guard got is Some(m) else { fail("no front matter") }
  assert_eq(m.keys().to_array(), ["b", "a"])
}

///|
test "split errors" {
  let cases = [
    ("unclosed", "---\ntitle: x\n", "no closing"),
    ("only opening", "---", "no closing"),
    (
      "line without colon", "---\ntitle: x\njust text\n---\n", "line 3: want \"key: value\", got \"just text\"",
    ),
    ("empty key", "---\n: x\n---\n", "line 2"),
    ("duplicate key", "---\na: 1\na: 2\n---\n", "line 3: duplicate key \"a\""),
  ]
  for (name, src, want) in cases {
    let msg = try @tinyfrontmatter.split(src) catch {
      SplitError(msg) => msg
    } noraise {
      _ => fail("\{name}: want an error")
    }
    assert_true(msg.contains(want), msg="\{name}: got \{msg}, want \{want}")
  }
}
