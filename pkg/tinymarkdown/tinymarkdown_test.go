package tinymarkdown

import (
	"reflect"
	"testing"
)

type testCase struct {
	name string
	src  string
	want Document
}

func run(t *testing.T, cases []testCase) {
	t.Helper()
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			got := Parse(c.src)
			if !reflect.DeepEqual(got, c.want) {
				t.Errorf("Parse(%q)\ngot  %#v\nwant %#v", c.src, got, c.want)
			}
		})
	}
}

func TestSectionsAndParagraphs(t *testing.T) {
	run(t, []testCase{
		{"empty", "", Document{}},
		{"blank lines only", "\n  \n\n", Document{}},
		{"paragraph", "hello", Document{Children: []Block{Paragraph{Text: "hello"}}}},
		{"lines join into one paragraph", "a\nb\r\n  c  ",
			Document{Children: []Block{Paragraph{Text: "a\nb\nc"}}}},
		{"blank line separates paragraphs", "a\n\nb",
			Document{Children: []Block{Paragraph{Text: "a"}, Paragraph{Text: "b"}}}},
		{"paragraph before first heading stays at root", "intro\n# Title\nbody",
			Document{Children: []Block{
				Paragraph{Text: "intro"},
				Section{Level: 1, Title: "Title", Children: []Block{Paragraph{Text: "body"}}},
			}}},
		{"heading ends a paragraph without a blank line", "a\n## H",
			Document{Children: []Block{Paragraph{Text: "a"}, Section{Level: 2, Title: "H"}}}},
		{"nested sections", "# A\na\n## B\nb\n### C\nc\n## D\n# E",
			Document{Children: []Block{
				Section{Level: 1, Title: "A", Children: []Block{
					Paragraph{Text: "a"},
					Section{Level: 2, Title: "B", Children: []Block{
						Paragraph{Text: "b"},
						Section{Level: 3, Title: "C", Children: []Block{Paragraph{Text: "c"}}},
					}},
					Section{Level: 2, Title: "D"},
				}},
				Section{Level: 1, Title: "E"},
			}}},
		{"level jump nests under the shallower heading", "# A\n### C\n## B",
			Document{Children: []Block{
				Section{Level: 1, Title: "A", Children: []Block{
					Section{Level: 3, Title: "C"},
					Section{Level: 2, Title: "B"},
				}},
			}}},
		{"heading title is trimmed", "#   spaced   ",
			Document{Children: []Block{Section{Level: 1, Title: "spaced"}}}},
		{"#### and ##### nest", "#### D\nd\n##### E\ne\n#### F",
			Document{Children: []Block{
				Section{Level: 4, Title: "D", Children: []Block{
					Paragraph{Text: "d"},
					Section{Level: 5, Title: "E", Children: []Block{Paragraph{Text: "e"}}},
				}},
				Section{Level: 4, Title: "F"},
			}}},
		{"###### is not a heading", "###### deep",
			Document{Children: []Block{Paragraph{Text: "###### deep"}}}},
		{"# without a space is not a heading", "#tag",
			Document{Children: []Block{Paragraph{Text: "#tag"}}}},
		{"bare # is not a heading", "#",
			Document{Children: []Block{Paragraph{Text: "#"}}}},
		{"inline syntax is kept as is", "**bold** [link](/x)",
			Document{Children: []Block{Paragraph{Text: "**bold** [link](/x)"}}}},
	})
}

func TestLists(t *testing.T) {
	run(t, []testCase{
		{"list", "- a\n-   b  \n  - c",
			Document{Children: []Block{List{Items: []string{"a", "b", "c"}}}}},
		{"blank line splits lists", "- a\n\n- b",
			Document{Children: []Block{List{Items: []string{"a"}}, List{Items: []string{"b"}}}}},
		{"list after paragraph without a blank line", "intro\n- a\n- b",
			Document{Children: []Block{Paragraph{Text: "intro"}, List{Items: []string{"a", "b"}}}}},
		{"paragraph after list without a blank line", "- a\nafter",
			Document{Children: []Block{List{Items: []string{"a"}}, Paragraph{Text: "after"}}}},
		{"indented lines continue an item", "- a\n  more\n\tand more\n- b\n  b2",
			Document{Children: []Block{List{Items: []string{"a\nmore\nand more", "b\nb2"}}}}},
		{"indented line after a paragraph stays in the paragraph", "p\n  q",
			Document{Children: []Block{Paragraph{Text: "p\nq"}}}},
		{"blank line ends the continuation", "- a\n\n  b",
			Document{Children: []Block{List{Items: []string{"a"}}, Paragraph{Text: "b"}}}},
		{"dash without a space is paragraph text", "-a\n--",
			Document{Children: []Block{Paragraph{Text: "-a\n--"}}}},
		{"list inside a section", "# A\n- x\n## B\n- y",
			Document{Children: []Block{
				Section{Level: 1, Title: "A", Children: []Block{
					List{Items: []string{"x"}},
					Section{Level: 2, Title: "B", Children: []Block{List{Items: []string{"y"}}}},
				}},
			}}},
	})
}

func TestCodeBlocks(t *testing.T) {
	run(t, []testCase{
		{"code block", "```\nfmt.Println(1)\n```",
			Document{Children: []Block{CodeBlock{Code: "fmt.Println(1)"}}}},
		{"language name is ignored", "```go\nx := 1\n```",
			Document{Children: []Block{CodeBlock{Code: "x := 1"}}}},
		{"contents are kept verbatim", "```\n# not a heading\n- not a list\n\n\tindented  \n```",
			Document{Children: []Block{CodeBlock{Code: "# not a heading\n- not a list\n\n\tindented  "}}}},
		{"empty code block", "```\n```",
			Document{Children: []Block{CodeBlock{Code: ""}}}},
		{"closing fence may have surrounding spaces", "```\na\n  ```  \nafter",
			Document{Children: []Block{CodeBlock{Code: "a"}, Paragraph{Text: "after"}}}},
		{"closing fence must be bare", "```\n```go\n```",
			Document{Children: []Block{CodeBlock{Code: "```go"}}}},
		{"CRLF line endings", "```\r\na\r\n```\r\n",
			Document{Children: []Block{CodeBlock{Code: "a"}}}},
		{"unclosed fence runs to EOF", "```\na\n\n# b",
			Document{Children: []Block{CodeBlock{Code: "a\n\n# b"}}}},
		{"fence ends a paragraph and a list", "p\n```\nc\n```\n- a\n```\nd\n```",
			Document{Children: []Block{
				Paragraph{Text: "p"}, CodeBlock{Code: "c"},
				List{Items: []string{"a"}}, CodeBlock{Code: "d"},
			}}},
		{"code block inside a section", "# A\n```\n## x\n```",
			Document{Children: []Block{
				Section{Level: 1, Title: "A", Children: []Block{CodeBlock{Code: "## x"}}},
			}}},
	})
}

func TestQuotes(t *testing.T) {
	run(t, []testCase{
		{"quote", "> a\n> b",
			Document{Children: []Block{Quote{Children: []Block{Paragraph{Text: "a\nb"}}}}}},
		{"space after > is optional", ">a\n  >  b",
			Document{Children: []Block{Quote{Children: []Block{Paragraph{Text: "a\nb"}}}}}},
		{"bare > separates paragraphs", "> a\n>\n> b",
			Document{Children: []Block{Quote{Children: []Block{Paragraph{Text: "a"}, Paragraph{Text: "b"}}}}}},
		{"blocks inside a quote", "> - x\n>   y\n> ```\n>   code\n> ```",
			Document{Children: []Block{Quote{Children: []Block{
				List{Items: []string{"x\ny"}}, CodeBlock{Code: "  code"},
			}}}}},
		{"nested quote", "> a\n>\n> > b",
			Document{Children: []Block{Quote{Children: []Block{
				Paragraph{Text: "a"}, Quote{Children: []Block{Paragraph{Text: "b"}}},
			}}}}},
		{"quote ends a paragraph and a list", "p\n> q\n- a\n> r",
			Document{Children: []Block{
				Paragraph{Text: "p"}, Quote{Children: []Block{Paragraph{Text: "q"}}},
				List{Items: []string{"a"}}, Quote{Children: []Block{Paragraph{Text: "r"}}},
			}}},
		{"a line without > ends the quote", "> q\np\n> r\n\n> s",
			Document{Children: []Block{
				Quote{Children: []Block{Paragraph{Text: "q"}}}, Paragraph{Text: "p"},
				Quote{Children: []Block{Paragraph{Text: "r"}}}, Quote{Children: []Block{Paragraph{Text: "s"}}},
			}}},
		{"quote inside a section", "# A\n> q",
			Document{Children: []Block{
				Section{Level: 1, Title: "A", Children: []Block{Quote{Children: []Block{Paragraph{Text: "q"}}}}},
			}}},
		{"> inside a code block is code", "```\n> x\n```",
			Document{Children: []Block{CodeBlock{Code: "> x"}}}},
	})
}

func TestTables(t *testing.T) {
	run(t, []testCase{
		{"table", "| a | b |\n| --- | --- |\n| 1 | `2` |\n| 3 | 4 |",
			Document{Children: []Block{Table{
				Header: []string{"a", "b"},
				Rows:   [][]string{{"1", "`2`"}, {"3", "4"}},
			}}}},
		{"header only", "| a |\n|---|",
			Document{Children: []Block{Table{Header: []string{"a"}}}}},
		{"trailing pipe is optional", "| a | b\n| --- | ---\n| 1 | 2",
			Document{Children: []Block{Table{Header: []string{"a", "b"}, Rows: [][]string{{"1", "2"}}}}}},
		{"alignment is accepted and ignored", "| a | b | c |\n| :-- | :-: | --: |",
			Document{Children: []Block{Table{Header: []string{"a", "b", "c"}}}}},
		{"rows are padded and cut to the header", "| a | b |\n| - | - |\n| 1 |\n| 1 | 2 | 3 |\n| | x |",
			Document{Children: []Block{Table{
				Header: []string{"a", "b"},
				Rows:   [][]string{{"1", ""}, {"1", "2"}, {"", "x"}},
			}}}},
		{"escaped pipe", "| a \\| b |\n| --- |\n| `x \\| y` |",
			Document{Children: []Block{Table{Header: []string{"a | b"}, Rows: [][]string{{"`x | y`"}}}}}},
		{"no delimiter row is a paragraph", "| a |\n| b |",
			Document{Children: []Block{Paragraph{Text: "| a |\n| b |"}}}},
		{"delimiter count must match", "| a | b |\n| --- |",
			Document{Children: []Block{Paragraph{Text: "| a | b |\n| --- |"}}}},
		{"single line is a paragraph", "| a |",
			Document{Children: []Block{Paragraph{Text: "| a |"}}}},
		{"table between paragraphs", "intro\n| a |\n| - |\n| 1 |\nafter",
			Document{Children: []Block{
				Paragraph{Text: "intro"},
				Table{Header: []string{"a"}, Rows: [][]string{{"1"}}},
				Paragraph{Text: "after"},
			}}},
		{"blank line splits tables", "| a |\n| - |\n\n| b |\n| - |",
			Document{Children: []Block{Table{Header: []string{"a"}}, Table{Header: []string{"b"}}}}},
		{"indented rows", "  | a |\n  | - |\n  | 1 |",
			Document{Children: []Block{Table{Header: []string{"a"}, Rows: [][]string{{"1"}}}}}},
		{"table in a section and a quote", "# T\n| a |\n| - |\n> | b |\n> | - |",
			Document{Children: []Block{Section{Level: 1, Title: "T", Children: []Block{
				Table{Header: []string{"a"}},
				Quote{Children: []Block{Table{Header: []string{"b"}}}},
			}}}}},
		{"list ends at a table", "- x\n| a |\n| - |",
			Document{Children: []Block{List{Items: []string{"x"}}, Table{Header: []string{"a"}}}}},
	})
}
