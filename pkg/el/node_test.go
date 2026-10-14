package el

import (
	"reflect"
	"testing"
)

func TestConstructors(t *testing.T) {
	cases := []struct {
		name string
		got  Node
		want Node
	}{
		{"text", Text("hi"), TextNode("hi")},
		{"raw", Raw("<b>"), RawNode("<b>")},
		{"attr", Attr(Class, "x"), AttrNode{Name: "class", Value: "x"}},
		{"bool attr", BoolAttrNode("hidden"), BoolAttrNode("hidden")},
		{"empty element", El(Br), ElementNode{Name: "br"}},
		{
			"nested element",
			El(Div, Attr(ID, "a"), El(P, Text("hi"))),
			ElementNode{Name: "div", Children: []Node{
				AttrNode{Name: "id", Value: "a"},
				ElementNode{Name: "p", Children: []Node{TextNode("hi")}},
			}},
		},
		{"dynamic names", El(Tag("my-widget"), Attr(AttrName("data-id"), "1")),
			ElementNode{Name: "my-widget", Children: []Node{AttrNode{Name: "data-id", Value: "1"}}}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if !reflect.DeepEqual(c.got, c.want) {
				t.Errorf("got %#v, want %#v", c.got, c.want)
			}
		})
	}
}

func TestLeafNodesAreComparable(t *testing.T) {
	s := "a"
	if Text(s) != TextNode("a") {
		t.Error("TextNode should compare equal with ==")
	}
	href := "/"
	if Attr(Href, href) != (AttrNode{Name: "href", Value: "/"}) {
		t.Error("AttrNode should compare equal with ==")
	}
}
