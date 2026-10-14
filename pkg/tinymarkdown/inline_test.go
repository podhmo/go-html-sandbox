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
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			if got := Inlines(c.src); !reflect.DeepEqual(got, c.want) {
				t.Errorf("Inlines(%q)\ngot  %#v\nwant %#v", c.src, got, c.want)
			}
		})
	}
}
