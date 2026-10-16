// The cases of go/pkg/tinymarkdown's tests, with the same names.
import { describe, expect, test } from "vitest";
import { type Block, type Inline, type Item, inlines, parse } from "./tinymarkdown.ts";

const P = (text: string): Block => ({ kind: "paragraph", text });
const S = (level: number, title: string, ...children: Block[]): Block => ({ kind: "section", level, title, children });
const I = (text: string, ...children: Item[]): Item => ({ text, children });
const L = (...items: (Item | string)[]): Block => ({ kind: "list", items: items.map((it) => (typeof it === "string" ? I(it) : it)) });
const Q = (...children: Block[]): Block => ({ kind: "quote", children });
const T = (header: string[], rows: string[][] = []): Block => ({ kind: "table", header, rows });
const C = (code: string): Block => ({ kind: "code", code });

function run(cases: [name: string, src: string, want: Block[]][]) {
  for (const [name, src, want] of cases) {
    test(name, () => expect(parse(src)).toEqual({ children: want }));
  }
}

describe("sections and paragraphs", () => {
  run([
    ["empty", "", []],
    ["blank lines only", "\n  \n\n", []],
    ["paragraph", "hello", [P("hello")]],
    ["lines join into one paragraph", "a\nb\r\n  c  ", [P("a\nb\nc")]],
    ["blank line separates paragraphs", "a\n\nb", [P("a"), P("b")]],
    ["paragraph before first heading stays at root", "intro\n# Title\nbody", [P("intro"), S(1, "Title", P("body"))]],
    ["heading ends a paragraph without a blank line", "a\n## H", [P("a"), S(2, "H")]],
    [
      "nested sections",
      "# A\na\n## B\nb\n### C\nc\n## D\n# E",
      [S(1, "A", P("a"), S(2, "B", P("b"), S(3, "C", P("c"))), S(2, "D")), S(1, "E")],
    ],
    ["level jump nests under the shallower heading", "# A\n### C\n## B", [S(1, "A", S(3, "C"), S(2, "B"))]],
    ["heading title is trimmed", "#   spaced   ", [S(1, "spaced")]],
    ["#### and ##### nest", "#### D\nd\n##### E\ne\n#### F", [S(4, "D", P("d"), S(5, "E", P("e"))), S(4, "F")]],
    ["###### is not a heading", "###### deep", [P("###### deep")]],
    ["# without a space is not a heading", "#tag", [P("#tag")]],
    ["bare # is not a heading", "#", [P("#")]],
    ["inline syntax is kept as is", "**bold** [link](/x)", [P("**bold** [link](/x)")]],
  ]);
});

describe("lists", () => {
  run([
    ["list", "- a\n-   b  \n- c", [L("a", "b", "c")]],
    ["blank line splits lists", "- a\n\n- b", [L("a"), L("b")]],
    ["list after paragraph without a blank line", "intro\n- a\n- b", [P("intro"), L("a", "b")]],
    ["paragraph after list without a blank line", "- a\nafter", [L("a"), P("after")]],
    ["indented lines continue an item", "- a\n  more\n\tand more\n- b\n  b2", [L("a\nmore\nand more", "b\nb2")]],
    ["indented line after a paragraph stays in the paragraph", "p\n  q", [P("p\nq")]],
    ["blank line ends the continuation", "- a\n\n  b", [L("a"), P("b")]],
    ["dash without a space is paragraph text", "-a\n--", [P("-a\n--")]],
    ["list inside a section", "# A\n- x\n## B\n- y", [S(1, "A", L("x"), S(2, "B", L("y")))]],
  ]);
});

describe("nested lists", () => {
  run([
    ["indented item nests under the one above", "- a\n  - b\n  - c\n- d", [L(I("a", I("b"), I("c")), "d")]],
    ["deeper nesting", "- a\n  - b\n    - c\n- d", [L(I("a", I("b", I("c"))), "d")]],
    ["dedent goes back to the matching level", "- a\n  - b\n    - c\n  - d", [L(I("a", I("b", I("c")), I("d")))]],
    ["any deeper indent nests, a shallower one is a sibling", "- a\n    - b\n  - c\n\t- d", [L(I("a", I("b"), I("c"), I("d")))]],
    ["indented lines continue the nearest item", "- a\n  more\n  - b\n    b2\n  b3\n- c", [L(I("a\nmore", I("b\nb2\nb3")), "c")]],
    ["an indented first item is the top level", "  - a\n- b\n  - c", [L("a", I("b", I("c")))]],
    ["indented item after a paragraph starts a list", "p\n  - a", [P("p"), L("a")]],
    ["blank line splits nested lists too", "- a\n\n  - b", [L("a"), L("b")]],
    ["checkboxes are text", "- [ ] a\n  - [x] b", [L(I("[ ] a", I("[x] b")))]],
    ["nested list in a quote", "> - a\n>   - b", [Q(L(I("a", I("b"))))]],
  ]);
});

describe("code blocks", () => {
  run([
    ["code block", "```\nfmt.Println(1)\n```", [C("fmt.Println(1)")]],
    ["language name is ignored", "```go\nx := 1\n```", [C("x := 1")]],
    ["contents are kept verbatim", "```\n# not a heading\n- not a list\n\n\tindented  \n```", [C("# not a heading\n- not a list\n\n\tindented  ")]],
    ["empty code block", "```\n```", [C("")]],
    ["closing fence may have surrounding spaces", "```\na\n  ```  \nafter", [C("a"), P("after")]],
    ["closing fence must be bare", "```\n```go\n```", [C("```go")]],
    ["CRLF line endings", "```\r\na\r\n```\r\n", [C("a")]],
    ["unclosed fence runs to EOF", "```\na\n\n# b", [C("a\n\n# b")]],
    ["fence ends a paragraph and a list", "p\n```\nc\n```\n- a\n```\nd\n```", [P("p"), C("c"), L("a"), C("d")]],
    ["code block inside a section", "# A\n```\n## x\n```", [S(1, "A", C("## x"))]],
  ]);
});

describe("quotes", () => {
  run([
    ["quote", "> a\n> b", [Q(P("a\nb"))]],
    ["space after > is optional", ">a\n  >  b", [Q(P("a\nb"))]],
    ["bare > separates paragraphs", "> a\n>\n> b", [Q(P("a"), P("b"))]],
    ["blocks inside a quote", "> - x\n>   y\n> ```\n>   code\n> ```", [Q(L("x\ny"), C("  code"))]],
    ["nested quote", "> a\n>\n> > b", [Q(P("a"), Q(P("b")))]],
    ["quote ends a paragraph and a list", "p\n> q\n- a\n> r", [P("p"), Q(P("q")), L("a"), Q(P("r"))]],
    ["a line without > ends the quote", "> q\np\n> r\n\n> s", [Q(P("q")), P("p"), Q(P("r")), Q(P("s"))]],
    ["quote inside a section", "# A\n> q", [S(1, "A", Q(P("q")))]],
    ["> inside a code block is code", "```\n> x\n```", [C("> x")]],
  ]);
});

describe("tables", () => {
  run([
    ["table", "| a | b |\n| --- | --- |\n| 1 | `2` |\n| 3 | 4 |", [T(["a", "b"], [["1", "`2`"], ["3", "4"]])]],
    ["header only", "| a |\n|---|", [T(["a"])]],
    ["trailing pipe is optional", "| a | b\n| --- | ---\n| 1 | 2", [T(["a", "b"], [["1", "2"]])]],
    ["alignment is accepted and ignored", "| a | b | c |\n| :-- | :-: | --: |", [T(["a", "b", "c"])]],
    ["rows are padded and cut to the header", "| a | b |\n| - | - |\n| 1 |\n| 1 | 2 | 3 |\n| | x |", [T(["a", "b"], [["1", ""], ["1", "2"], ["", "x"]])]],
    ["escaped pipe", "| a \\| b |\n| --- |\n| `x \\| y` |", [T(["a | b"], [["`x | y`"]])]],
    ["no delimiter row is a paragraph", "| a |\n| b |", [P("| a |\n| b |")]],
    ["delimiter count must match", "| a | b |\n| --- |", [P("| a | b |\n| --- |")]],
    ["single line is a paragraph", "| a |", [P("| a |")]],
    ["table between paragraphs", "intro\n| a |\n| - |\n| 1 |\nafter", [P("intro"), T(["a"], [["1"]]), P("after")]],
    ["blank line splits tables", "| a |\n| - |\n\n| b |\n| - |", [T(["a"]), T(["b"])]],
    ["indented rows", "  | a |\n  | - |\n  | 1 |", [T(["a"], [["1"]])]],
    ["table in a section and a quote", "# T\n| a |\n| - |\n> | b |\n> | - |", [S(1, "T", T(["a"]), Q(T(["b"])))]],
    ["list ends at a table", "- x\n| a |\n| - |", [L("x"), T(["a"])]],
  ]);
});

describe("inlines", () => {
  const t = (text: string): Inline => ({ kind: "text", text });
  const c = (text: string): Inline => ({ kind: "code", text });
  const a = (url: string, ...children: Inline[]): Inline => ({ kind: "link", children, url });
  const cases: [string, string, Inline[]][] = [
    ["empty", "", []],
    ["text only", "a b", [t("a b")]],
    ["code", "use `go test` now", [t("use "), c("go test"), t(" now")]],
    ["code only", "`x`", [c("x")]],
    ["several spans", "`a` and `b`", [c("a"), t(" and "), c("b")]],
    ["double backquotes hold a backquote", "``a ` b``", [c("a ` b")]],
    ["one space stripped from each end", "`` `x` ``", [c("`x`")]],
    ["spaces only are kept", "` `", [c(" ")]],
    ["space on one end is kept", "` a`", [c(" a")]],
    ["line break becomes a space", "`a\nb`", [c("a b")]],
    ["unclosed run is text", "a ` b", [t("a ` b")]],
    ["longer run does not close", "`a``", [t("`a``")]],
    ["unmatched run before a span", "`` x `y`", [t("`` x "), c("y")]],
    ["empty run pair is text", "``", [t("``")]],
    ["html stays text", "`<b>` <i>", [c("<b>"), t(" <i>")]],
    ["link", "see [docs](docs/a.md) now", [t("see "), a("docs/a.md", t("docs")), t(" now")]],
    ["link only", "[a](b)", [a("b", t("a"))]],
    ["link with code", "[`x` y](u)", [a("u", c("x"), t(" y"))]],
    ["bracket in code inside link", "[`]` y](u)", [a("u", c("]"), t(" y"))]],
    ["link in code is code", "`[a](b)`", [c("[a](b)")]],
    ["code across link is code", "[a `b](c)` d", [t("[a "), c("b](c)"), t(" d")]],
    ["empty url", "[a]()", [a("", t("a"))]],
    ["empty text", "[](u)", [a("u")]],
    ["fragment and query", "[a](https://x.test/p?q=1#f)", [a("https://x.test/p?q=1#f", t("a"))]],
    ["no url is text", "[a] (b)", [t("[a] (b)")]],
    ["brackets only are text", "[a]", [t("[a]")]],
    ["space in url is text", "[a](b c)", [t("[a](b c)")]],
    ["unclosed url is text", "[a](b", [t("[a](b")]],
    ["nested brackets: inner link", "[a [b](c)](d)", [t("[a "), a("c", t("b")), t("](d)")]],
    ["line break in text", "[a\nb](u)", [a("u", t("a\nb"))]],
    ["two links", "[a](1) [b](2)", [a("1", t("a")), t(" "), a("2", t("b"))]],
  ];
  for (const [name, src, want] of cases) {
    test(name, () => expect(inlines(src)).toEqual(want));
  }
});
