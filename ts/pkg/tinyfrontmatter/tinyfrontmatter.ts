// tinyfrontmatter splits a tiny front matter block from a document, as
// go/pkg/tinyfrontmatter does.
//
// The block starts with a "---" line at the very beginning of the document
// and ends with the next "---" line. In between, each non-blank line is
// "key: value". The value is everything after the first ":", trimmed; one
// pair of matching surrounding quotes is removed. Nothing else of YAML is
// supported.

const delimiter = "---";

// split returns the front matter of src and the rest of the document. If src
// does not start with a "---" line, meta is undefined and body is src.
export function split(src: string): { meta: Record<string, string> | undefined; body: string } {
  const lines = src.split("\n");
  if (trimLine(lines[0]) !== delimiter) return { meta: undefined, body: src };
  const meta: Record<string, string> = {};
  for (let i = 1; i < lines.length; i++) {
    const line = trimLine(lines[i]);
    if (line === delimiter) return { meta, body: lines.slice(i + 1).join("\n") };
    if (line === "") continue;
    const colon = line.indexOf(":");
    const key = colon < 0 ? "" : line.slice(0, colon).trim();
    if (key === "") throw new Error(`tinyfrontmatter: line ${i + 1}: want "key: value", got ${JSON.stringify(line)}`);
    if (Object.hasOwn(meta, key)) throw new Error(`tinyfrontmatter: line ${i + 1}: duplicate key ${JSON.stringify(key)}`);
    meta[key] = unquote(line.slice(colon + 1).trim());
  }
  throw new Error(`tinyfrontmatter: no closing "${delimiter}"`);
}

function trimLine(s: string): string {
  return s.replace(/[ \t\r]+$/, "");
}

function unquote(s: string): string {
  if (s.length >= 2 && (s[0] === '"' || s[0] === "'") && s[s.length - 1] === s[0]) return s.slice(1, -1);
  return s;
}
