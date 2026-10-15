///|
/// run_inlines checks inlines on each (name, src, want) case, reporting
/// every case whose result differs.
fn run_inlines(
  cases : Array[(String, String, Array[@tinymarkdown.Inline])],
) -> Unit raise {
  let failures = []
  for c in cases {
    let (name, src, want) = c
    let got = @tinymarkdown.inlines(src)
    if got != want {
      failures.push(
        "\{name}: inlines(\{@debug.to_string(src)})\ngot  \{@debug.to_string(got)}\nwant \{@debug.to_string(want)}",
      )
    }
  }
  if !failures.is_empty() {
    fail(failures.join("\n"))
  }
}

///|
// The cases of TestInlines in go/pkg/tinymarkdown.
test "inlines" {
  run_inlines([
    ("empty", "", []),
    ("text only", "a b", [Text("a b")]),
    ("code", "use `go test` now", [Text("use "), Code("go test"), Text(" now")]),
    ("code only", "`x`", [Code("x")]),
    ("several spans", "`a` and `b`", [Code("a"), Text(" and "), Code("b")]),
    ("double backquotes hold a backquote", "``a ` b``", [Code("a ` b")]),
    ("one space stripped from each end", "`` `x` ``", [Code("`x`")]),
    ("spaces only are kept", "` `", [Code(" ")]),
    ("space on one end is kept", "` a`", [Code(" a")]),
    ("line break becomes a space", "`a\nb`", [Code("a b")]),
    ("unclosed run is text", "a ` b", [Text("a ` b")]),
    ("longer run does not close", "`a``", [Text("`a``")]),
    ("unmatched run before a span", "`` x `y`", [Text("`` x "), Code("y")]),
    ("empty run pair is text", "``", [Text("``")]),
    ("html stays text", "`<b>` <i>", [Code("<b>"), Text(" <i>")]),
    (
      "link",
      "see [docs](docs/a.md) now",
      [
        Text("see "),
        Link(children=[Text("docs")], url="docs/a.md"),
        Text(" now"),
      ],
    ),
    ("link only", "[a](b)", [Link(children=[Text("a")], url="b")]),
    (
      "link with code",
      "[`x` y](u)",
      [Link(children=[Code("x"), Text(" y")], url="u")],
    ),
    (
      "bracket in code inside link",
      "[`]` y](u)",
      [Link(children=[Code("]"), Text(" y")], url="u")],
    ),
    ("link in code is code", "`[a](b)`", [Code("[a](b)")]),
    (
      "code across link is code",
      "[a `b](c)` d",
      [Text("[a "), Code("b](c)"), Text(" d")],
    ),
    ("empty url", "[a]()", [Link(children=[Text("a")], url="")]),
    ("empty text", "[](u)", [Link(children=[], url="u")]),
    (
      "fragment and query",
      "[a](https://x.test/p?q=1#f)",
      [Link(children=[Text("a")], url="https://x.test/p?q=1#f")],
    ),
    ("no url is text", "[a] (b)", [Text("[a] (b)")]),
    ("brackets only are text", "[a]", [Text("[a]")]),
    ("space in url is text", "[a](b c)", [Text("[a](b c)")]),
    ("unclosed url is text", "[a](b", [Text("[a](b")]),
    (
      "nested brackets: inner link",
      "[a [b](c)](d)",
      [Text("[a "), Link(children=[Text("b")], url="c"), Text("](d)")],
    ),
    (
      "line break in text",
      "[a\nb](u)",
      [Link(children=[Text("a\nb")], url="u")],
    ),
    (
      "two links",
      "[a](1) [b](2)",
      [
        Link(children=[Text("a")], url="1"),
        Text(" "),
        Link(children=[Text("b")], url="2"),
      ],
    ),
  ])
}
