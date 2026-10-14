package markdown

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
		{"#### is not a heading", "#### deep",
			Document{Children: []Block{Paragraph{Text: "#### deep"}}}},
		{"# without a space is not a heading", "#tag",
			Document{Children: []Block{Paragraph{Text: "#tag"}}}},
		{"bare # is not a heading", "#",
			Document{Children: []Block{Paragraph{Text: "#"}}}},
		{"inline syntax is kept as is", "**bold** [link](/x)",
			Document{Children: []Block{Paragraph{Text: "**bold** [link](/x)"}}}},
	})
}
