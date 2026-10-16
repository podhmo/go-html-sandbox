// tinymarkdown parses a tiny subset of Markdown into a pure-data tree, as
// go/pkg/tinymarkdown does; its tests are the Go test cases.
//
// Supported: headings "#" to "#####" (which open nested sections), "- "
// list items (which may continue on indented lines and nest by
// indentation), paragraphs, "> " quotes, "|" tables, and code blocks fenced
// by exactly "```". Anything else is treated as paragraph text. Block
// parsing keeps inline syntax as text; inlines splits out code spans and
// links on request.

export type Document = { children: Block[] };

export type Block = Section | Paragraph | List | Quote | Table | CodeBlock;

// Section is a heading together with everything up to the next heading of
// the same or a shallower level.
export type Section = { kind: "section"; level: number; title: string; children: Block[] };

// Paragraph is a run of consecutive non-blank lines, joined with "\n".
export type Paragraph = { kind: "paragraph"; text: string };

// List is a run of consecutive "- " lines. Each item is nested under the
// nearest item above it whose "- " is indented less.
export type List = { kind: "list"; items: Item[] };

// Item is a list item: the text after "- " and the items nested under it.
// Indented lines that follow an item without "- " continue its text.
export type Item = { text: string; children: Item[] };

// Quote is a run of lines starting with ">", whose content is parsed again
// as a document.
export type Quote = { kind: "quote"; children: Block[] };

// Table is a header row, a delimiter row, and body rows. Every row has as
// many cells as the header; alignment is accepted but ignored.
export type Table = { kind: "table"; header: string[]; rows: string[][] };

// CodeBlock is the verbatim content between "```" fences.
export type CodeBlock = { kind: "code"; code: string };

const fence = "```";
const maxLevel = 5;

// Heading is a parsed heading line, kept flat until nest builds sections.
type Heading = { kind: "heading"; level: number; title: string };
type RawItem = { indent: number; text: string };

// parse parses src. It never fails: lines it does not understand become
// paragraph text.
export function parse(src: string): Document {
  const [children] = nest(scan(src), 0, 0);
  return { children };
}

function scan(src: string): (Block | Heading)[] {
  const out: (Block | Heading)[] = [];
  let para: string[] = [];
  let quote: string[] = [];
  let table: string[] = [];
  let items: RawItem[] = [];
  const flush = () => {
    if (para.length > 0) {
      out.push({ kind: "paragraph", text: para.join("\n") });
      para = [];
    }
    if (items.length > 0) {
      out.push({ kind: "list", items: nestItems(items, 0, -1)[0] });
      items = [];
    }
    if (quote.length > 0) {
      out.push({ kind: "quote", children: parse(quote.join("\n")).children });
      quote = [];
    }
    if (table.length > 0) {
      out.push(parseTable(table) ?? { kind: "paragraph", text: table.join("\n") });
      table = [];
    }
  };
  let code: string[] = [];
  let inCode = false;
  for (let line of src.split("\n")) {
    if (line.endsWith("\r")) line = line.slice(0, -1);
    const trimmed = line.trim();
    if (inCode) {
      if (trimmed === fence) {
        out.push({ kind: "code", code: code.join("\n") });
        code = [];
        inCode = false;
      } else {
        code.push(line);
      }
      continue;
    }
    if (trimmed.startsWith(fence)) {
      flush();
      inCode = true;
    } else if (trimmed === "") {
      flush();
    } else if (isHeading(trimmed)) {
      flush();
      out.push(parseHeading(trimmed));
    } else if (trimmed.startsWith("|")) {
      if (para.length > 0 || items.length > 0 || quote.length > 0) flush();
      table.push(trimmed);
    } else if (trimmed.startsWith(">")) {
      if (para.length > 0 || items.length > 0 || table.length > 0) flush();
      const rest = line.slice(line.indexOf(">") + 1);
      quote.push(rest.startsWith(" ") ? rest.slice(1) : rest);
    } else if (trimmed.startsWith("- ")) {
      if (para.length > 0 || quote.length > 0 || table.length > 0) flush();
      items.push({ indent: indent(line), text: trimmed.slice(2).trim() });
    } else if (items.length > 0 && line !== trimmed && (line[0] === " " || line[0] === "\t")) {
      // An indented line continues the item above it.
      items[items.length - 1].text += "\n" + trimmed;
    } else {
      if (items.length > 0 || quote.length > 0 || table.length > 0) flush();
      para.push(trimmed);
    }
  }
  if (inCode) {
    // An unclosed fence runs to the end of the document.
    out.push({ kind: "code", code: code.join("\n") });
  }
  flush();
  return out;
}

function indent(line: string): number {
  return line.length - line.replace(/^[ \t]+/, "").length;
}

// nestItems consumes items from flat[i:] while they are indented deeper
// than parent, returning them and the index where it stopped.
function nestItems(flat: RawItem[], i: number, parent: number): [Item[], number] {
  const out: Item[] = [];
  while (i < flat.length && flat[i].indent > parent) {
    const it: Item = { text: flat[i].text, children: [] };
    [it.children, i] = nestItems(flat, i + 1, flat[i].indent);
    out.push(it);
  }
  return [out, i];
}

// parseTable returns undefined, leaving the lines to be a paragraph, unless
// the second line is a delimiter row with as many cells as the header.
function parseTable(lines: string[]): Table | undefined {
  if (lines.length < 2) return undefined;
  const header = cells(lines[0]);
  const delim = cells(lines[1]);
  if (delim.length !== header.length || !delim.every(isDelimiter)) return undefined;
  const rows = lines.slice(2).map((line) => {
    const row = cells(line).slice(0, header.length);
    while (row.length < header.length) row.push("");
    return row;
  });
  return { kind: "table", header, rows };
}

// cells splits a row such as "| a | b |" at unescaped "|".
function cells(line: string): string[] {
  if (line.startsWith("|")) line = line.slice(1);
  const out: string[] = [];
  let b = "";
  for (let i = 0; i < line.length; i++) {
    if (line[i] === "\\" && line[i + 1] === "|") {
      b += "|";
      i++;
    } else if (line[i] === "|") {
      out.push(b.trim());
      b = "";
    } else {
      b += line[i];
    }
  }
  if (b.trim() !== "") out.push(b.trim());
  return out;
}

function isDelimiter(c: string): boolean {
  return /^:?-+:?$/.test(c);
}

function isHeading(line: string): boolean {
  const n = line.search(/[^#]/);
  return 1 <= n && n <= maxLevel && line[n] === " ";
}

function parseHeading(line: string): Heading {
  const n = line.indexOf(" ");
  return { kind: "heading", level: n, title: line.slice(n).trim() };
}

// nest consumes blocks from flat[i:] until a heading at or above level,
// returning the children and the index where it stopped.
function nest(flat: (Block | Heading)[], i: number, level: number): [Block[], number] {
  const out: Block[] = [];
  while (i < flat.length) {
    const h = flat[i];
    if (h.kind !== "heading") {
      out.push(h);
      i++;
      continue;
    }
    if (h.level <= level) break;
    const sec: Section = { kind: "section", level: h.level, title: h.title, children: [] };
    [sec.children, i] = nest(flat, i + 1, h.level);
    out.push(sec);
  }
  return [out, i];
}

// Inline is a piece of the text held by a section title, a paragraph, a
// list item, or a table cell.
export type Inline =
  | { kind: "text"; text: string }
  | { kind: "code"; text: string }
  | { kind: "link"; children: Inline[]; url: string };

// inlines splits s into text, code spans, and links, as Go's Inlines does:
// a code span closes with the next run of as many backquotes, and a link is
// "[text](url)" with no brackets in the text outside code spans and no
// spaces or parentheses in the URL. Code spans bind tighter than links.
export function inlines(s: string): Inline[] {
  return parseInlines(s, true);
}

function parseInlines(s: string, links: boolean): Inline[] {
  const out: Inline[] = [];
  let text = 0; // start of the plain text not yet emitted
  const emit = (i: number, inl: Inline) => {
    if (text < i) out.push({ kind: "text", text: s.slice(text, i) });
    out.push(inl);
  };
  for (let i = 0; i < s.length; ) {
    if (s[i] === "`") {
      const n = backquotes(s, i);
      const end = closingRun(s, i + n, n);
      if (end < 0) {
        i += n;
        continue;
      }
      emit(i, { kind: "code", text: codeText(s.slice(i + n, end)) });
      i = end + n;
      text = i;
    } else if (s[i] === "[" && links) {
      const l = link(s, i);
      if (!l) {
        i++;
        continue;
      }
      emit(i, { kind: "link", children: parseInlines(l.label, false), url: l.url });
      i = l.end;
      text = i;
    } else {
      i++;
    }
  }
  if (text < s.length) out.push({ kind: "text", text: s.slice(text) });
  return out;
}

function link(s: string, i: number): { label: string; url: string; end: number } | undefined {
  let j = i + 1;
  for (; j < s.length && s[j] !== "]"; j++) {
    if (s[j] === "[") return undefined;
    if (s[j] === "`") {
      const n = backquotes(s, j);
      const c = closingRun(s, j + n, n);
      j = c >= 0 ? c + n - 1 : j + n - 1;
    }
  }
  if (j + 1 >= s.length || s[j + 1] !== "(") return undefined;
  let k = j + 2;
  for (; k < s.length && s[k] !== ")"; k++) {
    if (" \t\n(".includes(s[k])) return undefined;
  }
  if (k >= s.length) return undefined;
  return { label: s.slice(i + 1, j), url: s.slice(j + 2, k), end: k + 1 };
}

function backquotes(s: string, i: number): number {
  let j = i;
  while (j < s.length && s[j] === "`") j++;
  return j - i;
}

function closingRun(s: string, from: number, n: number): number {
  for (let j = from; j < s.length; ) {
    if (s[j] !== "`") {
      j++;
      continue;
    }
    const m = backquotes(s, j);
    if (m === n) return j;
    j += m;
  }
  return -1;
}

function codeText(s: string): string {
  s = s.replaceAll("\n", " ");
  if (s.length >= 2 && s[0] === " " && s[s.length - 1] === " " && /[^ ]/.test(s)) {
    s = s.slice(1, -1);
  }
  return s;
}
