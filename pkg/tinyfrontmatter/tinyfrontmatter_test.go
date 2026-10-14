package tinyfrontmatter

import (
	"reflect"
	"strings"
	"testing"
)

func TestSplit(t *testing.T) {
	cases := []struct {
		name     string
		src      string
		wantMeta map[string]string
		wantBody string
	}{
		{"no front matter", "# Title\nbody", nil, "# Title\nbody"},
		{"empty document", "", nil, ""},
		{"--- not on the first line", "\n---\na: b\n---\n", nil, "\n---\na: b\n---\n"},
		{"front matter",
			"---\ntitle: Hello\ndescription: A short post.\n---\n# Hello\n",
			map[string]string{"title": "Hello", "description": "A short post."},
			"# Hello\n"},
		{"empty front matter", "---\n---\nbody", map[string]string{}, "body"},
		{"closing at EOF without newline", "---\na: b\n---", map[string]string{"a": "b"}, ""},
		{"blank lines are skipped", "---\n\na: b\n  \n---\n", map[string]string{"a": "b"}, ""},
		{"value keeps later colons", "---\ntitle: Go: the basics\n---\n",
			map[string]string{"title": "Go: the basics"}, ""},
		{"spaces are trimmed", "---  \n  key  :   value  \n---\t\n", map[string]string{"key": "value"}, ""},
		{"surrounding quotes are removed", "---\na: \"x: y\"\nb: 'z'\nc: \"mismatch'\nd: \"\n---\n",
			map[string]string{"a": "x: y", "b": "z", "c": "\"mismatch'", "d": "\""}, ""},
		{"empty value", "---\na:\n---\n", map[string]string{"a": ""}, ""},
		{"CRLF", "---\r\ntitle: Hello\r\n---\r\nbody\r\n", map[string]string{"title": "Hello"}, "body\r\n"},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			meta, body, err := Split(c.src)
			if err != nil {
				t.Fatal(err)
			}
			if !reflect.DeepEqual(meta, c.wantMeta) {
				t.Errorf("meta: got %#v, want %#v", meta, c.wantMeta)
			}
			if body != c.wantBody {
				t.Errorf("body: got %q, want %q", body, c.wantBody)
			}
		})
	}
}

func TestSplitErrors(t *testing.T) {
	cases := []struct {
		name    string
		src     string
		wantErr string
	}{
		{"unclosed", "---\ntitle: x\n", "no closing"},
		{"only opening", "---", "no closing"},
		{"line without colon", "---\ntitle: x\njust text\n---\n", `line 3: want "key: value"`},
		{"empty key", "---\n: x\n---\n", "line 2"},
		{"duplicate key", "---\na: 1\na: 2\n---\n", `line 3: duplicate key "a"`},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			meta, body, err := Split(c.src)
			if err == nil || !strings.Contains(err.Error(), c.wantErr) {
				t.Fatalf("got error %v, want it to contain %q", err, c.wantErr)
			}
			if meta != nil || body != "" {
				t.Errorf("want zero results on error, got %#v, %q", meta, body)
			}
		})
	}
}
