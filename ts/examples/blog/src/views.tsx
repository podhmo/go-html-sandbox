// The pages, written as the Go blog's views.go builds them with picoel:
// semantic elements styled by pico.css v2, and site.css for the rest.
import type { Child } from "hono/jsx";
import { jsxRenderer } from "hono/jsx-renderer";
import { type Block, type Inline, type Item, inlines } from "../../../pkg/tinymarkdown/tinymarkdown.ts";
import { type Doc, type Post, docPath, firstTitle, postPath } from "./content.ts";
import { type Linker, noLinks } from "./links.ts";
import * as sources from "./sources.ts";

const siteName = "blog";
export const siteDescription = "Notes rendered with Wasm.";
const repoHomeURL = "https://github.com/podhmo/html-sandbox";
const picoURL = "https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css";

// PageMeta describes a page for <head>. title and description may hold
// inline Markdown, which the layout reduces to plain text. OGP tags are
// written only when url is set, so error pages have none.
export type PageMeta = {
  title?: string; // without the site name; none for the top page
  description: string;
  url?: string;
  type?: "website" | "article";
};

declare module "hono" {
  interface ContextRenderer {
    (content: Child, meta: PageMeta): Response | Promise<Response>;
  }
}

// layout is the frame shared by every page; jsxRenderer writes the doctype.
export const layout = jsxRenderer(({ children, ...meta }) => {
  const title = plainText(meta.title ?? "");
  const description = plainText(meta.description);
  return (
    <html lang="ja" data-theme="dark">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="color-scheme" content="dark" />
        <link rel="stylesheet" href={picoURL} />
        <title>{title ? `${title} - ${siteName}` : siteName}</title>
        <meta name="description" content={description} />
        {meta.url && (
          <>
            <meta property="og:title" content={title || siteName} />
            <meta property="og:type" content={meta.type} />
            <meta property="og:url" content={meta.url} />
            <meta property="og:description" content={description} />
            <meta property="og:site_name" content={siteName} />
          </>
        )}
        <link rel="stylesheet" href={sources.siteCSS} />
        <link rel="icon" href={sources.favicon} type="image/svg+xml" />
      </head>
      <body>
        <header class="container">
          <Spread
            start={[
              <a href="/"><strong>{siteName}</strong></a>,
              <a href="/docs/">docs</a>,
            ]}
            end={[<a href={repoHomeURL}>github</a>]}
          />
        </header>
        <main class="container">{children}</main>
        <footer class="container">
          <small>Rendered with Wasm.</small>
        </footer>
      </body>
    </html>
  );
});

// Spread puts start at the leading edge and end at the trailing edge of one
// row, using pico's nav layout.
function Spread({ start, end }: { start: Child[]; end: Child[] }) {
  return (
    <nav>
      <ul>{start.map((c) => <li>{c}</li>)}</ul>
      <ul>{end.map((c) => <li>{c}</li>)}</ul>
    </nav>
  );
}

// PostList shows each post as a card: the title links to the post and the
// date below it is muted by hgroup.
export function PostList({ posts }: { posts: Post[] }) {
  return (
    <>
      <hgroup>
        <h1>Posts</h1>
        <p>blog by AI</p>
      </hgroup>
      {posts.map((p) => (
        <article>
          <hgroup>
            <h2><a href={postPath(p)}><Inlines text={p.title} link={noLinks} /></a></h2>
            <p><time datetime={p.date}>{p.date}</time></p>
          </hgroup>
        </article>
      ))}
    </>
  );
}

export function PostPage({ post, link }: { post: Post; link: Linker }) {
  return (
    <>
      <PageHeader info={<time datetime={post.date}>{post.date}</time>} href={`${postPath(post)}.md`} filename={post.file} />
      <Body title={post.title} blocks={post.doc} link={link} />
    </>
  );
}

// DocList links to every repository document, showing its file path below
// the title.
export function DocList({ docs }: { docs: Doc[] }) {
  return (
    <>
      <h1>Docs</h1>
      {docs.map((d) => (
        <article>
          <hgroup>
            <h2><a href={docPath(d)}><Inlines text={d.title} link={noLinks} /></a></h2>
            <p>{d.source}</p>
          </hgroup>
        </article>
      ))}
    </>
  );
}

export function DocPage({ doc, link }: { doc: Doc; link: Linker }) {
  return (
    <>
      <PageHeader info={<small>{doc.source}</small>} href={`${docPath(doc)}.md`} filename={doc.source.split("/").pop()!} />
      <Body title={doc.title} blocks={doc.doc} link={link} />
    </>
  );
}

export function ErrorPage({ title, message }: { title: string; message: string }) {
  return (
    <>
      <h1>{title}</h1>
      <p>{message}</p>
      <p><a href="/">Back to all posts</a></p>
    </>
  );
}

// PageHeader is the row above the article: info on the left and a small
// link that downloads the page's Markdown source on the right.
function PageHeader({ info, href, filename }: { info: Child; href: string; filename: string }) {
  const download = <small><a href={href} download={filename} class="secondary">Download .md</a></small>;
  return (
    <header>
      <Spread start={[info]} end={[download]} />
    </header>
  );
}

// Body is the article. When the title came from front matter only, the
// body has no heading, so one is added.
function Body({ title, blocks, link }: { title: string; blocks: Post["doc"]; link: Linker }) {
  return (
    <article>
      {firstTitle(blocks) === undefined && <h1><Inlines text={title} link={link} /></h1>}
      <Blocks blocks={blocks.children} link={link} />
    </article>
  );
}

// Blocks renders the Markdown tree. hono/jsx escapes every string, so HTML
// in posts shows as text.
function Blocks({ blocks, link }: { blocks: Block[]; link: Linker }) {
  return (
    <>
      {blocks.map((b) => {
        switch (b.kind) {
          case "section": {
            const H = `h${b.level}` as "h1";
            return (
              <section>
                <H><Inlines text={b.title} link={link} /></H>
                <Blocks blocks={b.children} link={link} />
              </section>
            );
          }
          case "paragraph":
            return <p><Inlines text={b.text} link={link} /></p>;
          case "list":
            return <List items={b.items} link={link} />;
          case "quote":
            return <blockquote><Blocks blocks={b.children} link={link} /></blockquote>;
          case "table":
            // pico's overflow-auto lets a wide table scroll sideways.
            return (
              <div class="overflow-auto">
                <table>
                  <thead><tr>{b.header.map((c) => <th><Inlines text={c} link={link} /></th>)}</tr></thead>
                  {b.rows.length > 0 && (
                    <tbody>
                      {b.rows.map((r) => <tr>{r.map((c) => <td><Inlines text={c} link={link} /></td>)}</tr>)}
                    </tbody>
                  )}
                </table>
              </div>
            );
          case "code":
            return <pre>{b.code}</pre>;
        }
      })}
    </>
  );
}

function List({ items, link }: { items: Item[]; link: Linker }) {
  return (
    <ul>
      {items.map((it) => (
        <li>
          <Inlines text={it.text} link={link} />
          {it.children.length > 0 && <List items={it.children} link={link} />}
        </li>
      ))}
    </ul>
  );
}

// Inlines turns code spans into <code> and links into <a>. A link whose
// URL link rejects shows only its text.
function Inlines({ text, link }: { text: string; link: Linker }) {
  return <>{renderInlines(inlines(text), link)}</>;
}

function renderInlines(ins: Inline[], link: Linker): Child[] {
  return ins.map((inl) => {
    switch (inl.kind) {
      case "text":
        return inl.text;
      case "code":
        return <code>{inl.text}</code>;
      case "link": {
        const children = renderInlines(inl.children, link);
        const href = link(inl.url);
        return href === undefined ? <>{children}</> : <a href={href}>{children}</a>;
      }
    }
  });
}

// plainText drops the markup of inline Markdown, for places that hold no
// HTML, such as <title>.
function plainText(s: string): string {
  const walk = (ins: Inline[]): string =>
    ins.map((inl) => (inl.kind === "link" ? walk(inl.children) : inl.text)).join("");
  return walk(inlines(s));
}
