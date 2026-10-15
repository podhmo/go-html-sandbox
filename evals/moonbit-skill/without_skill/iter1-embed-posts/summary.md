# Embed go/examples/blog/posts/*.md for MoonBit (without skill)

## What was done
Two commits in the clone (not pushed): e1a0111 and 3bef269.

- New package `moonbit/posts`. It exposes `pub let posts : Array[(String, String)]`, which holds
  (file name, content) pairs sorted by file name. The names are the same as Go's `posts.FS`
  (e.g. `2026-10-14-hello.md`). The code is in `posts/posts_gen.mbt`, which is generated
  and git-ignored (`moonbit/.gitignore`).
- `moonbit/scripts/embed-posts.sh` (POSIX sh + awk) is the generator. Each line becomes a
  `#|` multiline-string line, so nothing needs escaping, and a file's trailing newline is
  kept. It writes to a temp file and replaces the output only if the content changed
  (`cmp`), so moon does not rebuild needlessly.
- `moonbit/Makefile` has a new `gen` target that always runs the script. `build`, `test`
  and `check` depend on it, and `clean` removes the generated file. The first version used
  mtime prerequisites, but GNU make 3.81 compares mtimes by the second and missed a
  change made in the same second. The second commit fixes that.
- In `moonbit/workers/wrangler.jsonc`, the build command is now `cd .. && make build && ...`.
  `watch_dir` now also covers `../scripts` and `../../go/examples/blog/posts`. It does not
  cover `../posts`, where the build writes.
- `site` imports `posts`, and the top page lists the post file names. This makes the
  embedding show in the Wasm and in `wrangler dev`. `site_test` checks for one of the names.
- Tests (`posts/posts_test.mbt`) check:
  - the exact list of names (the completeness check);
  - that each post ends with exactly one newline;
  - the start of the hello post and of the mobile-first post (front matter and non-ASCII text).
- `moonbit/README.md` and `TODO.md` are updated. In `TODO.md`, "記事と文書を埋め込む" is now
  `[-]`, with a done `[x] 記事` child and an open `[ ] 文書` child for TODO.md and
  docs/**/*.md.

## Why not moon's pre-build
I tried it in a scratch module.
- `:embed` (`moon tool embed`) takes one file per rule.
- A custom pre-build command works: it runs from the module dir through a shell, with
  `$mod_dir`, `$input` and `$output` available.
- A glob input fails ("input .../*.md missing").
- A directory input reruns only when files are added or removed, not when a post is edited.
So I used a make-driven script, as the TODO suggested as the fallback. The downside: plain
`moon test` in a fresh clone fails until you run `make gen` (this is documented in the
README).

## Commands and results
- `make check`: moon fmt --check OK (the generated file is fmt-stable), moon check OK,
  `Total tests: 4, passed: 4, failed: 0.`
- `make build`: `worker.wasm` is 15815 bytes. Its UTF-16 data contains the post text
  (checked with python).
- From clean `git clone`s (twice, after each commit), `make build` and then `make check`
  both passed. Afterwards, `git status --ignored` showed only `_build/` and
  `posts/posts_gen.mbt` as ignored, with nothing untracked.
- Regeneration checks:
  - Editing a post → `make gen` rewrites the file. Reverting → rewritten back.
  - An unchanged run keeps the file's mtime.
  - Adding or removing a post shows up.
- `make dev PORT=18151`:
  - `curl -i /` gave 200, `text/html; charset=utf-8`, and listed all 4 posts.
  - Adding `2026-10-19-tmp.md` → wrangler logged "changed, restarting build", ran
    `make build`, and the page listed it within about 2s. Removing it → gone within about 2s.
  - The Worker was stopped afterwards.

## Sources consulted
- `~/.moon/AGENTS.md`, the "Pre-build Commands" section
- `moon tool embed --help`
- Repo files: moonbit/{Makefile, README.md, moon.mod, site/*, worker/moon.pkg,
  workers/wrangler.jsonc}, TODO.md, .claude/skills/todo-md/SKILL.md,
  go/examples/blog/posts/embed.go, go/examples/blog/internal/site/content.go
- I did not use the moonbit skill and did not read its SKILL.md.

## Issues
- `.claude/skills/moonbit/*` was already deleted in the working tree by the sandbox setup.
  I did not commit those deletions, and I excluded them from diff.patch
  (`git diff 62c287d -- . ':(exclude).claude/skills/moonbit'`).
- `inspect` on `Array[String]` gives a deprecation warning (Show used for debugging), so I
  switched to `debug_inspect`.
- My first test assumed every post starts with "# ". Two posts start with front matter, so
  I fixed the test.
