package el

import (
	"bytes"
	"testing"
)

// benchPage builds a tree shaped like an article page: paragraphs, a nested
// list, and a table, which is what HTMLRenderer spends its time on.
func benchPage(paragraphs int) Node {
	paras := make([]Node, 0, paragraphs)
	for range paragraphs {
		paras = append(paras, El(P,
			Text("Text with <angle> brackets & ampersands, then "),
			El(Code, Text("inline code")),
			Text(" and a "),
			El(A, Attr(Href, "/posts/a-post-with-a-longish-slug"), Text("link")),
			Text(" to another page."),
		))
	}
	items := make([]Node, 0, 20)
	for i := range 20 {
		items = append(items, El(Li,
			El(A, Attr(Href, "/docs/ja/design"), Text("a document")),
			Text(" item "),
			El(Code, Text("code")),
		))
		if i%5 == 0 {
			items = append(items, El(Ul, El(Li, Text("nested")), El(Li, Text("items"))))
		}
	}
	rows := make([]Node, 0, 20)
	for range 20 {
		rows = append(rows, El(Tr,
			El(Td, Text("cell with & and <")),
			El(Td, El(Code, Text("0.4 ms"))),
		))
	}
	return El(Article,
		El(H1, Text("A page title")),
		El(Hgroup, paras...),
		El(Ul, items...),
		El(Table, El(Tbody, rows...)),
	)
}

func BenchmarkRenderHTML(b *testing.B) {
	page := benchPage(200)
	var buf bytes.Buffer
	if err := Render(&buf, page, HTMLRenderer{}); err != nil {
		b.Fatal(err)
	}
	b.SetBytes(int64(buf.Len()))
	b.ReportAllocs()
	for b.Loop() {
		buf.Reset()
		if err := Render(&buf, page, HTMLRenderer{}); err != nil {
			b.Fatal(err)
		}
	}
}
