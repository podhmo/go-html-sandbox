// The blog's routes, exercised with app.request as Hono's docs suggest,
// over the posts and documents embed wrote.
import { describe, expect, test } from "vitest";
import app from "./app.tsx";
import { loadPosts } from "./content.ts";
import { linker } from "./links.ts";

const env = { BASE_URL: "https://example.com" };
const get = (path: string, init?: RequestInit) => app.request(path, init, env);

describe("pages", () => {
  test("the post list links to every post, newest first", async () => {
    const res = await get("/");
    expect(res.status).toBe(200);
    const html = await res.text();
    expect(html.startsWith("<!DOCTYPE html>")).toBe(true);
    expect(html).toContain('<meta property="og:url" content="https://example.com/"/>');
    const slugs = [...html.matchAll(/<a href="\/posts\/([a-z0-9-]+)">/g)].map((m) => m[1]);
    expect(slugs.at(-1)).toBe("hello");
  });

  test("a post has its title, OGP tags, and a link to its source", async () => {
    const html = await (await get("/posts/hello")).text();
    expect(html).toContain("<title>Hello - blog</title>");
    expect(html).toContain('<meta property="og:type" content="article"/>');
    expect(html).toContain('<a href="/posts/hello.md" download="2026-10-14-hello.md" class="secondary">');
  });

  test("HTML in posts is escaped", async () => {
    const html = await (await get("/posts/tinymarkdown")).text();
    expect(html).toContain("&lt;b&gt;これ&lt;/b&gt;");
    expect(html).not.toContain("<b>これ</b>");
  });

  test("a document is served by its path", async () => {
    const res = await get("/docs/ja/design");
    expect(res.status).toBe(200);
    expect(await res.text()).toContain("<small>docs/ja/design.md</small>");
  });

  test("the sources are served as Markdown", async () => {
    for (const path of ["/posts/hello.md", "/docs/TODO.md"]) {
      const res = await get(path);
      expect(res.status).toBe(200);
      expect(res.headers.get("Content-Type")).toBe("text/markdown; charset=utf-8");
      expect(res.headers.get("X-Content-Type-Options")).toBe("nosniff");
    }
    expect(await (await get("/posts/hello.md")).text()).toMatch(/^# Hello\n/);
  });

  test("/docs redirects to /docs/", async () => {
    const res = await get("/docs");
    expect(res.status).toBe(307);
    expect(res.headers.get("Location")).toBe("/docs/");
  });
});

describe("errors", () => {
  test.each([
    ["/no-such-page", "Page not found."],
    ["/posts/no-such-post", "Post not found."],
    ["/posts/no-such-post.md", "Post not found."],
    ["/docs/no-such-doc", "Document not found."],
  ])("%s is a 404 page", async (path, message) => {
    const res = await get(path);
    expect(res.status).toBe(404);
    const html = await res.text();
    expect(html).toContain(`<p>${message}</p>`);
    expect(html).not.toContain("og:url");
  });

  test("methods other than GET and HEAD get the 404 page", async () => {
    expect((await get("/", { method: "POST" })).status).toBe(404);
    expect((await get("/", { method: "HEAD" })).status).toBe(200);
  });
});

describe("loadPosts", () => {
  const post = (file: string, markdown = "# T\n") => ({ file, markdown });

  test("takes the title and description from front matter or the body", () => {
    const [a, b] = loadPosts([
      post("2026-01-02-a.md", "---\ntitle: From `meta`\n---\nFirst\nparagraph.\n"),
      post("2026-01-01-b.md", "# Heading\n\nintro"),
    ]);
    expect([a.title, a.description]).toEqual(["From `meta`", "First paragraph."]);
    expect([b.title, b.description]).toEqual(["Heading", "intro"]);
  });

  test.each([
    [[post("hello.md")], "file name must look like"],
    [[post("2026-02-30-a.md")], "is not a date"],
    [[post("2026-01-01-a.md"), post("2026-01-02-a.md")], 'slug "a" is already used'],
    [[post("2026-01-01-a.md", "no title")], "no title"],
    [[post("2026-01-01-a.md", "---\ntags: x\n---\n# T")], 'unknown front matter key "tags"'],
    [[post("2026-01-01-a.md", "---\ntitle: x\n")], "2026-01-01-a.md: tinyfrontmatter: no closing"],
  ])("rejects %j", (files, message) => {
    expect(() => loadPosts(files)).toThrow(message);
  });
});

describe("linker", () => {
  const posts = loadPosts([{ file: "2026-01-01-hello.md", markdown: "# Hello" }]);
  const docs = [{ path: "ja/design", source: "docs/ja/design.md", title: "", description: "", doc: { children: [] }, markdown: "" }];
  const link = linker("TODO.md", posts, docs);

  test.each([
    ["docs/ja/design.md#x", "/docs/ja/design#x"],
    ["posts/2026-01-01-hello.md", "/posts/hello"],
    ["go/README.md?plain=1", "https://github.com/podhmo/html-sandbox/blob/main/go/README.md?plain=1"],
    ["go/", "https://github.com/podhmo/html-sandbox/blob/main/go"],
    ["https://example.com", "https://example.com"],
    ["MAILTO:a@example.com", "MAILTO:a@example.com"],
    ["/abs", "/abs"],
    ["#frag", "#frag"],
    ["../outside", undefined],
    ["javascript:alert(1)", undefined],
  ])("%s", (url, want) => {
    expect(link(url)).toBe(want);
  });

  test("relative to the file's directory", () => {
    expect(linker("docs/sketch/ja/blog.md", posts, docs)("../../ja/design.md")).toBe("/docs/ja/design");
  });
});
