package tinymarkdown

import (
	"reflect"
	"testing"
)

func TestInlines(t *testing.T) {
	cases := []struct {
		name string
		src  string
		want []Inline
	}{
		{"empty", "", nil},
		{"text only", "a b", []Inline{Text("a b")}},
		{"code", "use `go test` now", []Inline{Text("use "), Code("go test"), Text(" now")}},
		{"code only", "`x`", []Inline{Code("x")}},
		{"several spans", "`a` and `b`", []Inline{Code("a"), Text(" and "), Code("b")}},
		{"double backquotes hold a backquote", "``a ` b``", []Inline{Code("a ` b")}},
		{"one space stripped from each end", "`` `x` ``", []Inline{Code("`x`")}},
		{"spaces only are kept", "` `", []Inline{Code(" ")}},
		{"space on one end is kept", "` a`", []Inline{Code(" a")}},
		{"line break becomes a space", "`a\nb`", []Inline{Code("a b")}},
		{"unclosed run is text", "a ` b", []Inline{Text("a ` b")}},
		{"longer run does not close", "`a``", []Inline{Text("`a``")}},
		{"unmatched run before a span", "`` x `y`", []Inline{Text("`` x "), Code("y")}},
		{"empty run pair is text", "``", []Inline{Text("``")}},
		{"html stays text", "`<b>` <i>", []Inline{Code("<b>"), Text(" <i>")}},
		{"link", "see [docs](docs/a.md) now", []Inline{Text("see "), Link([]Inline{Text("docs")}, "docs/a.md"), Text(" now")}},
		{"link only", "[a](b)", []Inline{Link([]Inline{Text("a")}, "b")}},
		{"link with code", "[`x` y](u)", []Inline{Link([]Inline{Code("x"), Text(" y")}, "u")}},
		{"bracket in code inside link", "[`]` y](u)", []Inline{Link([]Inline{Code("]"), Text(" y")}, "u")}},
		{"link in code is code", "`[a](b)`", []Inline{Code("[a](b)")}},
		{"code across link is code", "[a `b](c)` d", []Inline{Text("[a "), Code("b](c)"), Text(" d")}},
		{"empty url", "[a]()", []Inline{Link([]Inline{Text("a")}, "")}},
		{"empty text", "[](u)", []Inline{Link(nil, "u")}},
		{"fragment and query", "[a](https://x.test/p?q=1#f)", []Inline{Link([]Inline{Text("a")}, "https://x.test/p?q=1#f")}},
		{"no url is text", "[a] (b)", []Inline{Text("[a] (b)")}},
		{"brackets only are text", "[a]", []Inline{Text("[a]")}},
		{"space in url is text", "[a](b c)", []Inline{Text("[a](b c)")}},
		{"unclosed url is text", "[a](b", []Inline{Text("[a](b")}},
		{"nested brackets: inner link", "[a [b](c)](d)", []Inline{Text("[a "), Link([]Inline{Text("b")}, "c"), Text("](d)")}},
		{"line break in text", "[a\nb](u)", []Inline{Link([]Inline{Text("a\nb")}, "u")}},
		{"two links", "[a](1) [b](2)", []Inline{Link([]Inline{Text("a")}, "1"), Text(" "), Link([]Inline{Text("b")}, "2")}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := Inlines(c.src); !reflect.DeepEqual(got, c.want) {
				t.Errorf("Inlines(%q)\ngot  %#v\nwant %#v", c.src, got, c.want)
			}
		})
	}
}
