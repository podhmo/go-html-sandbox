// The blog as a Hono app, and the Worker's entry point. favicon.svg and
// site.css never reach it: Workers serves them from public/ as static
// assets, before the Worker runs.
import { Hono, type Context } from "hono";
import { loadDocs, loadPosts } from "./content.ts";
import { linker } from "./links.ts";
import { DocList, DocPage, ErrorPage, PostList, PostPage, layout, siteDescription } from "./views.tsx";
import content from "./content.gen.json" with { type: "json" };

type Env = {
  Bindings: {
    // BASE_URL is the public origin for OGP tags, e.g. https://example.com.
    BASE_URL: string;
  };
};

// The posts and documents are parsed once, when the isolate starts.
const posts = loadPosts(content.posts);
const docs = loadDocs(content.docs);
const bySlug = new Map(posts.map((p) => [p.slug, p]));
const byPath = new Map(docs.map((d) => [d.path, d]));

const app = new Hono<Env>();
app.use(layout);

function notFound(c: Context<Env>, message: string) {
  c.status(404);
  return c.render(<ErrorPage title="404 Not Found" message={message} />, { title: "404 Not Found", description: message });
}

// markdown serves the source of a page. nosniff keeps browsers from
// guessing that Markdown containing tags is HTML.
function markdown(c: Context<Env>, src: string) {
  return c.body(src, 200, { "Content-Type": "text/markdown; charset=utf-8", "X-Content-Type-Options": "nosniff" });
}

app.get("/", (c) =>
  c.render(<PostList posts={posts} />, { description: siteDescription, url: `${c.env.BASE_URL}/`, type: "website" }),
);

app.get("/posts/:slug", (c) => {
  const slug = c.req.param("slug");
  const post = bySlug.get(slug.replace(/\.md$/, ""));
  if (!post) return notFound(c, "Post not found.");
  if (slug.endsWith(".md")) return markdown(c, post.markdown);
  return c.render(<PostPage post={post} link={linker(`posts/${post.file}`, posts, docs)} />, {
    title: post.title,
    description: post.description,
    url: `${c.env.BASE_URL}/posts/${post.slug}`,
    type: "article",
  });
});

app.get("/docs", (c) => c.redirect("/docs/", 307));

app.get("/docs/", (c) =>
  c.render(<DocList docs={docs} />, {
    title: "Docs",
    description: "Documents of this repository.",
    url: `${c.env.BASE_URL}/docs/`,
    type: "website",
  }),
);

app.get("/docs/:path{.+}", (c) => {
  const path = c.req.param("path");
  const doc = byPath.get(path.replace(/\.md$/, ""));
  if (!doc) return notFound(c, "Document not found.");
  if (path.endsWith(".md")) return markdown(c, doc.markdown);
  return c.render(<DocPage doc={doc} link={linker(doc.source, posts, docs)} />, {
    title: doc.title,
    description: doc.description,
    url: `${c.env.BASE_URL}/docs/${doc.path}`,
    type: "article",
  });
});

app.notFound((c) => notFound(c, "Page not found."));

app.onError((err, c) => {
  console.error(err);
  c.status(500);
  return c.render(<ErrorPage title="500 Internal Server Error" message="Something went wrong." />, {
    title: "500 Internal Server Error",
    description: "Something went wrong.",
  });
});

export default app;
