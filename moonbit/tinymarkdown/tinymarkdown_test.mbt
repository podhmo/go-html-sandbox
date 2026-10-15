///|
/// run checks parse on each (name, src, want) case, reporting every case
/// whose tree differs, like the Go table tests it mirrors.
fn run(
  cases : Array[(String, String, Array[@tinymarkdown.Block])],
) -> Unit raise {
  let failures = []
  for (name, src, want) in cases {
    let got = @tinymarkdown.parse(src)
    let want = @tinymarkdown.Document::{ children: want, }
    if got != want {
      failures.push(
        "\{name}: parse(\{@debug.to_string(src)})\ngot  \{@debug.to_string(got)}\nwant \{@debug.to_string(want)}",
      )
    }
  }
  if !failures.is_empty() {
    fail(failures.join("\n"))
  }
}

///|
/// items makes list items without children.
fn items(texts : Array[String]) -> Array[@tinymarkdown.Item] {
  texts.map(text => { text, children: [], })
}

///|
// The cases of TestSectionsAndParagraphs in go/pkg/tinymarkdown.
test "sections and paragraphs" {
  run([
    ("empty", "", []),
    ("blank lines only", "\n  \n\n", []),
    ("paragraph", "hello", [Paragraph("hello")]),
    ("lines join into one paragraph", "a\nb\r\n  c  ", [Paragraph("a\nb\nc")]),
    (
      "blank line separates paragraphs",
      "a\n\nb",
      [Paragraph("a"), Paragraph("b")],
    ),
    (
      "paragraph before first heading stays at root",
      "intro\n# Title\nbody",
      [
        Paragraph("intro"),
        Section(level=1, title="Title", children=[Paragraph("body")]),
      ],
    ),
    (
      "heading ends a paragraph without a blank line",
      "a\n## H",
      [Paragraph("a"), Section(level=2, title="H", children=[])],
    ),
    (
      "nested sections",
      "# A\na\n## B\nb\n### C\nc\n## D\n# E",
      [
        Section(level=1, title="A", children=[
          Paragraph("a"),
          Section(level=2, title="B", children=[
            Paragraph("b"),
            Section(level=3, title="C", children=[Paragraph("c")]),
          ]),
          Section(level=2, title="D", children=[]),
        ]),
        Section(level=1, title="E", children=[]),
      ],
    ),
    (
      "level jump nests under the shallower heading",
      "# A\n### C\n## B",
      [
        Section(level=1, title="A", children=[
          Section(level=3, title="C", children=[]),
          Section(level=2, title="B", children=[]),
        ]),
      ],
    ),
    (
      "heading title is trimmed",
      "#   spaced   ",
      [Section(level=1, title="spaced", children=[])],
    ),
    (
      "#### and ##### nest",
      "#### D\nd\n##### E\ne\n#### F",
      [
        Section(level=4, title="D", children=[
          Paragraph("d"),
          Section(level=5, title="E", children=[Paragraph("e")]),
        ]),
        Section(level=4, title="F", children=[]),
      ],
    ),
    ("###### is not a heading", "###### deep", [Paragraph("###### deep")]),
    ("# without a space is not a heading", "#tag", [Paragraph("#tag")]),
    ("bare # is not a heading", "#", [Paragraph("#")]),
    (
      "inline syntax is kept as is",
      "**bold** [link](/x)",
      [Paragraph("**bold** [link](/x)")],
    ),
  ])
}

///|
// The cases of TestLists in go/pkg/tinymarkdown.
test "lists" {
  run([
    ("list", "- a\n-   b  \n- c", [List(items(["a", "b", "c"]))]),
    (
      "blank line splits lists",
      "- a\n\n- b",
      [List(items(["a"])), List(items(["b"]))],
    ),
    (
      "list after paragraph without a blank line",
      "intro\n- a\n- b",
      [Paragraph("intro"), List(items(["a", "b"]))],
    ),
    (
      "paragraph after list without a blank line",
      "- a\nafter",
      [List(items(["a"])), Paragraph("after")],
    ),
    (
      "indented lines continue an item",
      "- a\n  more\n\tand more\n- b\n  b2",
      [List(items(["a\nmore\nand more", "b\nb2"]))],
    ),
    (
      "indented line after a paragraph stays in the paragraph",
      "p\n  q",
      [Paragraph("p\nq")],
    ),
    (
      "blank line ends the continuation",
      "- a\n\n  b",
      [List(items(["a"])), Paragraph("b")],
    ),
    ("dash without a space is paragraph text", "-a\n--", [Paragraph("-a\n--")]),
    (
      "list inside a section",
      "# A\n- x\n## B\n- y",
      [
        Section(level=1, title="A", children=[
          List(items(["x"])),
          Section(level=2, title="B", children=[List(items(["y"]))]),
        ]),
      ],
    ),
  ])
}

///|
// The cases of TestNestedLists in go/pkg/tinymarkdown.
test "nested lists" {
  run([
    (
      "indented item nests under the one above",
      "- a\n  - b\n  - c\n- d",
      [List([{ text: "a", children: items(["b", "c"]), }, ..items(["d"])])],
    ),
    (
      "deeper nesting",
      "- a\n  - b\n    - c\n- d",
      [
        List(
          [
            { text: "a", children: [{ text: "b", children: items(["c"]), }], },
            ..items(["d"]),
          ],
        ),
      ],
    ),
    (
      "dedent goes back to the matching level",
      "- a\n  - b\n    - c\n  - d",
      [
        List([
          {
            text: "a",
            children: [{ text: "b", children: items(["c"]), }, ..items(["d"])],
          },
        ]),
      ],
    ),
    (
      "any deeper indent nests, a shallower one is a sibling",
      "- a\n    - b\n  - c\n\t- d",
      [List([{ text: "a", children: items(["b", "c", "d"]), }])],
    ),
    (
      "indented lines continue the nearest item",
      "- a\n  more\n  - b\n    b2\n  b3\n- c",
      [
        List(
          [{ text: "a\nmore", children: items(["b\nb2\nb3"]), }, ..items(["c"])],
        ),
      ],
    ),
    (
      "an indented first item is the top level",
      "  - a\n- b\n  - c",
      [List([..items(["a"]), { text: "b", children: items(["c"]), }])],
    ),
    (
      "indented item after a paragraph starts a list",
      "p\n  - a",
      [Paragraph("p"), List(items(["a"]))],
    ),
    (
      "blank line splits nested lists too",
      "- a\n\n  - b",
      [List(items(["a"])), List(items(["b"]))],
    ),
    (
      "checkboxes are text",
      "- [ ] a\n  - [x] b",
      [List([{ text: "[ ] a", children: items(["[x] b"]), }])],
    ),
    (
      "nested list in a quote",
      "> - a\n>   - b",
      [Quote([List([{ text: "a", children: items(["b"]), }])])],
    ),
  ])
}

///|
// The cases of TestCodeBlocks in go/pkg/tinymarkdown.
test "code blocks" {
  run([
    ("code block", "```\nfmt.Println(1)\n```", [CodeBlock("fmt.Println(1)")]),
    ("language name is ignored", "```go\nx := 1\n```", [CodeBlock("x := 1")]),
    (
      "contents are kept verbatim",
      "```\n# not a heading\n- not a list\n\n\tindented  \n```",
      [CodeBlock("# not a heading\n- not a list\n\n\tindented  ")],
    ),
    ("empty code block", "```\n```", [CodeBlock("")]),
    (
      "closing fence may have surrounding spaces",
      "```\na\n  ```  \nafter",
      [CodeBlock("a"), Paragraph("after")],
    ),
    ("closing fence must be bare", "```\n```go\n```", [CodeBlock("```go")]),
    ("CRLF line endings", "```\r\na\r\n```\r\n", [CodeBlock("a")]),
    ("unclosed fence runs to EOF", "```\na\n\n# b", [CodeBlock("a\n\n# b")]),
    (
      "fence ends a paragraph and a list",
      "p\n```\nc\n```\n- a\n```\nd\n```",
      [Paragraph("p"), CodeBlock("c"), List(items(["a"])), CodeBlock("d")],
    ),
    (
      "code block inside a section",
      "# A\n```\n## x\n```",
      [Section(level=1, title="A", children=[CodeBlock("## x")])],
    ),
  ])
}

///|
// The cases of TestQuotes in go/pkg/tinymarkdown.
test "quotes" {
  run([
    ("quote", "> a\n> b", [Quote([Paragraph("a\nb")])]),
    ("space after > is optional", ">a\n  >  b", [Quote([Paragraph("a\nb")])]),
    (
      "bare > separates paragraphs",
      "> a\n>\n> b",
      [Quote([Paragraph("a"), Paragraph("b")])],
    ),
    (
      "blocks inside a quote",
      "> - x\n>   y\n> ```\n>   code\n> ```",
      [Quote([List(items(["x\ny"])), CodeBlock("  code")])],
    ),
    (
      "nested quote",
      "> a\n>\n> > b",
      [Quote([Paragraph("a"), Quote([Paragraph("b")])])],
    ),
    (
      "quote ends a paragraph and a list",
      "p\n> q\n- a\n> r",
      [
        Paragraph("p"),
        Quote([Paragraph("q")]),
        List(items(["a"])),
        Quote([Paragraph("r")]),
      ],
    ),
    (
      "a line without > ends the quote",
      "> q\np\n> r\n\n> s",
      [
        Quote([Paragraph("q")]),
        Paragraph("p"),
        Quote([Paragraph("r")]),
        Quote([Paragraph("s")]),
      ],
    ),
    (
      "quote inside a section",
      "# A\n> q",
      [Section(level=1, title="A", children=[Quote([Paragraph("q")])])],
    ),
    ("> inside a code block is code", "```\n> x\n```", [CodeBlock("> x")]),
  ])
}

///|
// The cases of TestTables in go/pkg/tinymarkdown.
test "tables" {
  run([
    (
      "table",
      "| a | b |\n| --- | --- |\n| 1 | `2` |\n| 3 | 4 |",
      [Table(header=["a", "b"], rows=[["1", "`2`"], ["3", "4"]])],
    ),
    ("header only", "| a |\n|---|", [Table(header=["a"], rows=[])]),
    (
      "trailing pipe is optional",
      "| a | b\n| --- | ---\n| 1 | 2",
      [Table(header=["a", "b"], rows=[["1", "2"]])],
    ),
    (
      "alignment is accepted and ignored",
      "| a | b | c |\n| :-- | :-: | --: |",
      [Table(header=["a", "b", "c"], rows=[])],
    ),
    (
      "rows are padded and cut to the header",
      "| a | b |\n| - | - |\n| 1 |\n| 1 | 2 | 3 |\n| | x |",
      [Table(header=["a", "b"], rows=[["1", ""], ["1", "2"], ["", "x"]])],
    ),
    (
      "escaped pipe",
      "| a \\| b |\n| --- |\n| `x \\| y` |",
      [Table(header=["a | b"], rows=[["`x | y`"]])],
    ),
    (
      "no delimiter row is a paragraph",
      "| a |\n| b |",
      [Paragraph("| a |\n| b |")],
    ),
    (
      "delimiter count must match",
      "| a | b |\n| --- |",
      [Paragraph("| a | b |\n| --- |")],
    ),
    ("single line is a paragraph", "| a |", [Paragraph("| a |")]),
    (
      "table between paragraphs",
      "intro\n| a |\n| - |\n| 1 |\nafter",
      [
        Paragraph("intro"),
        Table(header=["a"], rows=[["1"]]),
        Paragraph("after"),
      ],
    ),
    (
      "blank line splits tables",
      "| a |\n| - |\n\n| b |\n| - |",
      [Table(header=["a"], rows=[]), Table(header=["b"], rows=[])],
    ),
    (
      "indented rows",
      "  | a |\n  | - |\n  | 1 |",
      [Table(header=["a"], rows=[["1"]])],
    ),
    (
      "table in a section and a quote",
      "# T\n| a |\n| - |\n> | b |\n> | - |",
      [
        Section(level=1, title="T", children=[
          Table(header=["a"], rows=[]),
          Quote([Table(header=["b"], rows=[])]),
        ]),
      ],
    ),
    (
      "list ends at a table",
      "- x\n| a |\n| - |",
      [List(items(["x"])), Table(header=["a"], rows=[])],
    ),
  ])
}
