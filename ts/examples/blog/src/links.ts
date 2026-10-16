// Resolving the URLs of Markdown links, as the Go blog's links.go does.
import { type Doc, type Post, docPath, postPath } from "./content.ts";

// repoURL is where files of the repository that the site does not serve
// are linked to: the main branch on GitHub.
const repoURL = "https://github.com/podhmo/html-sandbox/blob/main";

// Linker resolves the URL of a link to an href, or undefined when the URL
// must not be linked; the link text is then shown as plain text.
export type Linker = (url: string) => string | undefined;

// noLinks is for titles inside a link to their page, as links cannot nest.
export const noLinks: Linker = () => undefined;

// linker returns the Linker for links written in the file at source (a
// path in the repository). Links with a scheme are kept for http, https,
// and mailto only. Links to "/..." and "#..." are kept as they are. Other
// links are relative to source, as on GitHub: those to a document or post
// served here go to its page, others go to the file on GitHub, and those
// that leave the repository are not linked.
export function linker(source: string, posts: Post[], docs: Doc[]): Linker {
  return (raw) => {
    const scheme = /^([a-zA-Z][a-zA-Z0-9+.-]*):/.exec(raw);
    if (scheme) return ["http", "https", "mailto"].includes(scheme[1].toLowerCase()) ? raw : undefined;
    if (raw === "" || raw.startsWith("/") || raw.startsWith("#")) return raw;
    // Resolve against a fake origin to join and clean the path; a path
    // that climbs out of the repository climbs above /repo/.
    const u = new URL(raw, `http://x/repo/${source}`);
    if (!u.pathname.startsWith("/repo/")) return undefined;
    const p = decodeURIComponent(u.pathname.slice("/repo/".length));
    const doc = docs.find((d) => d.source === p);
    const post = posts.find((post) => `posts/${post.file}` === p);
    if (doc) return docPath(doc) + u.hash;
    if (post) return postPath(post) + u.hash;
    return `${repoURL}/${p}`.replace(/\/$/, "") + u.search + u.hash;
  };
}
