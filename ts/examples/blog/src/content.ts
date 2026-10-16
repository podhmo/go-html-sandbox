// The posts and the repository's documents, loaded from the files embed
// wrote, as the Go blog's posts.go and docs.go load them.
import { type Block, type Document, parse } from "../../../pkg/tinymarkdown/tinymarkdown.ts";
import { split } from "../../../pkg/tinyfrontmatter/tinyfrontmatter.ts";

// Post is one blog post loaded from a YYYY-MM-DD-slug.md file.
export type Post = {
  slug: string;
  file: string; // file name, e.g. 2026-10-14-hello.md
  date: string; // YYYY-MM-DD
  title: string; // front matter "title", or the first "#" heading
  description: string; // front matter "description", or the first paragraph
  doc: Document;
  markdown: string; // the file as written, front matter included
};

// Doc is a repository document, such as TODO.md or docs/ja/design.md,
// served under /docs/.
export type Doc = {
  path: string; // URL path below /docs/: the file path without "docs/" and ".md"
  source: string; // file path in the repository
  title: string; // the first "#" heading, or source
  description: string; // the first paragraph
  doc: Document;
  markdown: string;
};

const frontMatterKeys = ["title", "description"];
const postName = /^(\d{4}-\d{2}-\d{2})-([a-z0-9]+(?:-[a-z0-9]+)*)\.md$/;

// loadPosts parses every post, newest first. Like the Go blog, it throws on
// a bad file name, a duplicate slug, a missing title, or an unknown front
// matter key, so a broken post stops the Worker instead of hiding.
export function loadPosts(files: { file: string; markdown: string }[]): Post[] {
  const seen = new Map<string, string>();
  const posts = files.map(({ file, markdown }) => {
    const m = postName.exec(file);
    if (!m) throw new Error(`${file}: file name must look like YYYY-MM-DD-slug.md (slug: a-z, 0-9, -)`);
    const [, date, slug] = m;
    if (Number.isNaN(Date.parse(date)) || new Date(date).toISOString().slice(0, 10) !== date) {
      throw new Error(`${file}: ${date} is not a date`);
    }
    const prev = seen.get(slug);
    if (prev) throw new Error(`${file}: slug "${slug}" is already used by ${prev}`);
    seen.set(slug, file);

    let meta: Record<string, string>, body: string;
    try {
      const fm = split(markdown);
      meta = fm.meta ?? {};
      body = fm.body;
    } catch (e) {
      throw new Error(`${file}: ${(e as Error).message}`);
    }
    for (const k of Object.keys(meta)) {
      if (!frontMatterKeys.includes(k)) throw new Error(`${file}: unknown front matter key "${k}" (want one of ${frontMatterKeys.join(", ")})`);
    }
    const doc = parse(body);
    const title = meta.title || firstTitle(doc);
    if (!title) throw new Error(`${file}: no title (set "title" in front matter or start with a "# title" heading)`);
    const description = meta.description || firstParagraph(doc.children);
    return { slug, file, date, title, description, doc, markdown };
  });
  return posts.sort((a, b) => b.date.localeCompare(a.date) || a.slug.localeCompare(b.slug));
}

// loadDocs parses every document, in the order given.
export function loadDocs(files: { source: string; markdown: string }[]): Doc[] {
  return files.map(({ source, markdown }) => {
    const doc = parse(markdown);
    return {
      path: source.replace(/^docs\//, "").replace(/\.md$/, ""),
      source,
      title: firstTitle(doc) ?? source,
      description: firstParagraph(doc.children),
      doc,
      markdown,
    };
  });
}

// firstTitle returns the title of the first top-level "#" section.
export function firstTitle(doc: Document): string | undefined {
  for (const b of doc.children) {
    if (b.kind === "section" && b.level === 1) return b.title;
  }
  return undefined;
}

// firstParagraph returns the first paragraph in document order, with line
// breaks turned into spaces.
function firstParagraph(bs: Block[]): string {
  for (const b of bs) {
    if (b.kind === "paragraph") return b.text.replaceAll("\n", " ");
    if (b.kind === "section") {
      const s = firstParagraph(b.children);
      if (s) return s;
    }
  }
  return "";
}

export const postPath = (p: Post) => `/posts/${p.slug}`;
export const docPath = (d: Doc) => `/docs/${d.path}`;
