# Add /about to the MoonBit site

## What I did

- `moonbit/site/site.mbt`: `render` gains a `"/about"` arm that renders an
  About page (title `About | blog`) with status 200, `content-type:
  text/html; charset=utf-8`, and `cache-control: public, max-age=60`
  (pushed onto `Response.headers`; no ABI change needed since headers already
  cross via `host.header_name`/`host.header_value`). Updated `render`'s doc comment.
- `moonbit/site/site_test.mbt`: added tests `about page` (status, content-type,
  cache-control, doctype, title, h1) and `other pages are not cached`
  (`/` and `/about/` have no cache-control; `/about/` is 404).
- Committed as `2044ce0 moonbit: add an /about page, cached for 60 seconds`.
- TODO.md and research notes untouched (not a TODO item; no new finding beyond size).

## Commands and results

- `moon version`: `moon 0.1.20261012 (748b63c 2026-10-12)`; version.json reports the
  same, so no upgrade needed.
- `.claude/skills/moonbit/scripts/sync-refs.sh`: core from ~/.moon/lib/core (0.10.15);
  moonbit-docs has no v0.10.15 tag yet -> origin/main; agent-guide origin/HEAD.
- `make check` (moonbit/): moon fmt --check OK, moon check OK,
  moon test "Total tests: 4, passed: 4, failed: 0."
- `make build`: worker.wasm 5279 bytes before -> 6268 bytes after (+989).
- `make dev PORT=18121`, then `curl -si localhost:18121/about`:
  ```
  HTTP/1.1 200 OK
  Content-Type: text/html; charset=utf-8
  Cache-Control: public, max-age=60

  <!doctype html>
  <html lang="ja"><head><meta charset="utf-8"><title>About | blog</title></head><body><h1>About</h1><p>This blog is rendered by MoonBit compiled to Wasm and served from Cloudflare Workers.</p></body></html>
  ```
  `/` -> 200 and `/nope` -> 404, both without Cache-Control. Dev server stopped
  (port 18121 confirmed free).

## Sources consulted

- .claude/skills/moonbit/SKILL.md, references/pitfalls.md
- moonbit/site/site.mbt, site_test.mbt, worker/worker.mbt, workers/worker.mjs,
  Makefile, TODO.md

## Problems

None.
