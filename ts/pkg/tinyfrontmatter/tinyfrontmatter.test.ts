// The cases of go/pkg/tinyfrontmatter's tests, with the same names.
import { expect, test } from "vitest";
import { split } from "./tinyfrontmatter.ts";

const cases: [string, string, Record<string, string> | undefined, string][] = [
  ["no front matter", "# Title\nbody", undefined, "# Title\nbody"],
  ["empty document", "", undefined, ""],
  ["--- not on the first line", "\n---\na: b\n---\n", undefined, "\n---\na: b\n---\n"],
  ["front matter", "---\ntitle: Hello\ndescription: A short post.\n---\n# Hello\n", { title: "Hello", description: "A short post." }, "# Hello\n"],
  ["empty front matter", "---\n---\nbody", {}, "body"],
  ["closing at EOF without newline", "---\na: b\n---", { a: "b" }, ""],
  ["blank lines are skipped", "---\n\na: b\n  \n---\n", { a: "b" }, ""],
  ["value keeps later colons", "---\ntitle: Go: the basics\n---\n", { title: "Go: the basics" }, ""],
  ["spaces are trimmed", "---  \n  key  :   value  \n---\t\n", { key: "value" }, ""],
  ["surrounding quotes are removed", "---\na: \"x: y\"\nb: 'z'\nc: \"mismatch'\nd: \"\n---\n", { a: "x: y", b: "z", c: "\"mismatch'", d: '"' }, ""],
  ["empty value", "---\na:\n---\n", { a: "" }, ""],
  ["CRLF", "---\r\ntitle: Hello\r\n---\r\nbody\r\n", { title: "Hello" }, "body\r\n"],
];
for (const [name, src, meta, body] of cases) {
  test(name, () => expect(split(src)).toEqual({ meta, body }));
}

const errors: [string, string, string][] = [
  ["unclosed", "---\ntitle: x\n", "no closing"],
  ["only opening", "---", "no closing"],
  ["line without colon", "---\ntitle: x\njust text\n---\n", 'line 3: want "key: value"'],
  ["empty key", "---\n: x\n---\n", "line 2"],
  ["duplicate key", "---\na: 1\na: 2\n---\n", 'line 3: duplicate key "a"'],
];
for (const [name, src, want] of errors) {
  test(name, () => expect(() => split(src)).toThrow(want));
}
