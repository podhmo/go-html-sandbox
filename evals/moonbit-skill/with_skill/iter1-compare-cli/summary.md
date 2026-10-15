# Summary: TODO "Go 版のブログと比べる" (compare the Go blog with the MoonBit Worker)

## What was done (commit 300ed88 on main in the clone, not pushed)

- `moonbit/compare/` (library, all targets): `Fetched`, `default_paths()`,
  `join_url`, `body_diff` (unified diff via core `@diff`, split after each `>` and
  newline because the Go pages are mostly one line; capped by `max_lines`),
  `compare(path, go, moonbit)` -> `Report` naming which of status / content-type /
  body differ, and `summary`. 10 blackbox tests in `compare/compare_test.mbt`
  (8 new + 2 existing site tests).
- `moonbit/compare/cmd/` (native-only executable): argparse
  `compare GO_URL MOONBIT_URL [PATH...] [--lines N]`, fetches with
  `moonbitlang/async/http` `@http.get` (no redirect following), prints a report
  per path and "N of M paths differ", exits 1 (via `fail`) if anything differs.
  (First put at `cmd/compare`, but its package alias `compare` collided with the
  library's, so it moved to `compare/cmd`.)
- `moonbit/moon.mod`: added `moonbitlang/async@0.22.5` (latest after `moon update`).
- `moonbit/worker/moon.pkg`: `supported_targets = "+wasm-gc"` (host imports fail
  on native with [4156] otherwise).
- `moonbit/Makefile`: `make compare` (GO_URL, MOONBIT_URL=http://localhost:$(PORT),
  PATHS=), and `make check` now also runs `moon check --target native`.
- `moonbit/README.md`, `docs/sketch/ja/moonbit-workers-wasm.md` (new section
  "Go 版との比較スクリプト" with results table, next-steps list updated),
  `TODO.md` (item `[x]`, parent `[ ]` -> `[-]`, per todo-md skill; archive untouched).

## Commands and results

- `moon version`: 0.1.20261012, same as `https://cli.moonbitlang.com/version.json` -> no upgrade needed.
- `.claude/skills/moonbit/scripts/sync-refs.sh async@0.22.5`: async at v0.22.5;
  moonbit-docs: no tag v0.10.15 yet, origin/main used.
- `moon update`, `moon add moonbitlang/async` -> 0.22.5.
- Wasm: `make build` 5,279 B, byte-identical (`cmp`) to a build of 62c287d in a
  temporary worktree; Node `WebAssembly.Module` exports `serve`, `path_push`,
  imports `host.put/status/header_value/header_name` (unchanged).
- Servers: `go generate ./...` then `go run ./examples/blog -addr localhost:18101`
  (from go/), `make dev PORT=18102` (from moonbit/). Both stopped at the end.

### make check

```
moon fmt --check
Finished. moon: no work to do
moon check
Finished. moon: ran 2 tasks, now up to date
moon check --target native
Finished. moon: no work to do
moon test
Total tests: 10, passed: 10, failed: 0.
```

### make compare GO_URL=http://localhost:18101 PORT=18102 (exit 1, as expected: everything differs at first)

```
moon run --target native compare/cmd -- http://localhost:18101 http://localhost:18102 
/: differs (body)
  body: go 1649 chars, moonbit 148 chars
    --- go
    +++ moonbit
    @@ -1,94 +1,15 @@
     <!doctype html>
     \n
    -<html lang="ja" data-theme="dark">
    +<html lang="ja">
     <head>
     <meta charset="utf-8">
    -<meta name="viewport" content="width=device-width, initial-scale=1">
    -<meta name="color-scheme" content="dark">
    -<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
     <title>
     blog</title>
    -<meta name="description" content="Notes rendered with the Go standard library only.">
    -<meta property="og:title" content="blog">
    -<meta property="og:type" content="website">
    -<meta property="og:url" content="http://localhost:18101/">
    -<meta property="og:description" content="Notes rendered with the Go standard library only.">
    -<meta property="og:site_name" content="blog">
    -<link rel="stylesheet" href="/site.css?v=cc9ec7c4">
    -<link rel="icon" href="/favicon.svg" type="image/svg+xml">
     </head>
     <body>
    -<header class="container">
    -<nav>
    -<ul>
    -<li>
    -<a href="/">
    -<strong>
    -blog</strong>
    -</a>
    -</li>
    -<li>
    -<a href="/docs/">
    -docs</a>
    -</li>
    -</ul>
    -</nav>
    -</header>
    -<main class="container">
     <h1>
    ... 58 more lines
/posts/hello: differs (status, body)
  status: go 200, moonbit 404
  body: go 1887 chars, moonbit 180 chars
    --- go
    +++ moonbit
    @@ -1,83 +1,17 @@
     <!doctype html>
     \n
    -<html lang="ja" data-theme="dark">
    +<html lang="ja">
     <head>
     <meta charset="utf-8">
    -<meta name="viewport" content="width=device-width, initial-scale=1">
    -<meta name="color-scheme" content="dark">
    -<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
     <title>
    -Hello - blog</title>
    -<meta name="description" content="This blog is rendered by the Go standard library only. There is no template engine, no CSS build step, and no JavaScript.">
    -<meta property="og:title" content="Hello">
    -<meta property="og:type" content="article">
    -<meta property="og:url" content="http://localhost:18101/posts/hello">
    -<meta property="og:description" content="This blog is rendered by the Go standard library only. There is no template engine, no CSS build step, and no JavaScript.">
    -<meta property="og:site_name" content="blog">
    -<link rel="stylesheet" href="/site.css?v=cc9ec7c4">
    -<link rel="icon" href="/favicon.svg" type="image/svg+xml">
    +Not found | blog</title>
     </head>
     <body>
    -<header class="container">
    -<nav>
    -<ul>
    -<li>
    -<a href="/">
    -<strong>
    -blog</strong>
    -</a>
    -</li>
    -<li>
    -<a href="/docs/">
    -docs</a>
    -</li>
    -</ul>
    -</nav>
    -</header>
    -<main class="container">
    ... 50 more lines
/docs/ja/design: differs (status, body)
  status: go 200, moonbit 404
  body: go 5100 chars, moonbit 183 chars
    --- go
    +++ moonbit
    @@ -1,336 +1,17 @@
     <!doctype html>
     \n
    -<html lang="ja" data-theme="dark">
    +<html lang="ja">
     <head>
     <meta charset="utf-8">
    -<meta name="viewport" content="width=device-width, initial-scale=1">
    -<meta name="color-scheme" content="dark">
    -<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
     <title>
    -メモ: Go 標準ライブラリだけの SSR 設計方針 - blog</title>
    -<meta name="description" content="Go の標準ライブラリだけで、古典的な SSR（サーバサイドレンダリング）の Web サービスを作る。gomponents の思想を取り入れるが、依存はゼロ。テンプレートエンジン（html/template）も使わない。">
    -<meta property="og:title" content="メモ: Go 標準ライブラリだけの SSR 設計方針">
    -<meta property="og:type" content="article">
    -<meta property="og:url" content="http://localhost:18101/docs/ja/design">
    -<meta property="og:description" content="Go の標準ライブラリだけで、古典的な SSR（サーバサイドレンダリング）の Web サービスを作る。gomponents の思想を取り入れるが、依存はゼロ。テンプレートエンジン（html/template）も使わない。">
    -<meta property="og:site_name" content="blog">
    -<link rel="stylesheet" href="/site.css?v=cc9ec7c4">
    -<link rel="icon" href="/favicon.svg" type="image/svg+xml">
    +Not found | blog</title>
     </head>
     <body>
    -<header class="container">
    -<nav>
    -<ul>
    -<li>
    -<a href="/">
    -<strong>
    -blog</strong>
    -</a>
    -</li>
    -<li>
    -<a href="/docs/">
    -docs</a>
    -</li>
    -</ul>
    -</nav>
    -</header>
    -<main class="container">
    ... 303 more lines
/docs/: differs (status, body)
  status: go 200, moonbit 404
  body: go 1784 chars, moonbit 174 chars
    --- go
    +++ moonbit
    @@ -1,98 +1,17 @@
     <!doctype html>
     \n
    -<html lang="ja" data-theme="dark">
    +<html lang="ja">
     <head>
     <meta charset="utf-8">
    -<meta name="viewport" content="width=device-width, initial-scale=1">
    -<meta name="color-scheme" content="dark">
    -<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
     <title>
    -Docs - blog</title>
    -<meta name="description" content="Documents of this repository.">
    -<meta property="og:title" content="Docs">
    -<meta property="og:type" content="website">
    -<meta property="og:url" content="http://localhost:18101/docs/">
    -<meta property="og:description" content="Documents of this repository.">
    -<meta property="og:site_name" content="blog">
    -<link rel="stylesheet" href="/site.css?v=cc9ec7c4">
    -<link rel="icon" href="/favicon.svg" type="image/svg+xml">
    +Not found | blog</title>
     </head>
     <body>
    -<header class="container">
    -<nav>
    -<ul>
    -<li>
    -<a href="/">
    -<strong>
    -blog</strong>
    -</a>
    -</li>
    -<li>
    -<a href="/docs/">
    -docs</a>
    -</li>
    -</ul>
    -</nav>
    -</header>
    -<main class="container">
    ... 65 more lines
/favicon.svg: differs (status, content-type, body)
  status: go 200, moonbit 404
  content-type: go "image/svg+xml", moonbit "text/html; charset=utf-8"
  body: go 248 chars, moonbit 180 chars
    --- go
    +++ moonbit
    @@ -1,5 +1,17 @@
    -<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
    -<rect width="32" height="32" rx="6" fill="#2563eb"/>
    -<path d="M9 8h9a5 5 0 0 1 0 10H9zm0 10h10a5 5 0 0 1 0 10H9z" fill="none" stroke="#fff" stroke-width="3" stroke-linejoin="round"/>
    -</svg>
    +<!doctype html>
     \n
    +<html lang="ja">
    +<head>
    +<meta charset="utf-8">
    +<title>
    +Not found | blog</title>
    +</head>
    +<body>
    +<h1>
    +Not found</h1>
    +<p>
    +No page at <code>
    +/favicon.svg</code>
    +.</p>
    +</body>
    +</html>
/no-such-page: differs (body)
  body: go 839 chars, moonbit 181 chars
    --- go
    +++ moonbit
    @@ -1,47 +1,17 @@
     <!doctype html>
     \n
    -<html lang="ja" data-theme="dark">
    +<html lang="ja">
     <head>
     <meta charset="utf-8">
    -<meta name="viewport" content="width=device-width, initial-scale=1">
    -<meta name="color-scheme" content="dark">
    -<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css">
     <title>
    -404 Not Found - blog</title>
    -<meta name="description" content="Page not found.">
    -<link rel="stylesheet" href="/site.css?v=cc9ec7c4">
    -<link rel="icon" href="/favicon.svg" type="image/svg+xml">
    +Not found | blog</title>
     </head>
     <body>
    -<header class="container">
    -<nav>
    -<ul>
    -<li>
    -<a href="/">
    -<strong>
    -blog</strong>
    -</a>
    -</li>
    -<li>
    -<a href="/docs/">
    -docs</a>
    -</li>
    -</ul>
    -</nav>
    -</header>
    -<main class="container">
     <h1>
    -404 Not Found</h1>
    +Not found</h1>
     <p>
    -Page not found.</p>
    ... 14 more lines
6 of 6 paths differ
Failure(compare/cmd/main.mbt:71:5-71:29@podhmo/blog FAILED: 6 of 6 paths differ)
make: *** [compare] Error 1
```

Other runs:
- `make compare ... PATHS="/favicon.svg /posts/nope"` -> 2 of 2 differ.
- Go vs Go (`compare http://localhost:18101 http://localhost:18101/`) -> all 6 `same`, `0 of 6 paths differ`, exit 0.

## Sources consulted

- `.claude/skills/moonbit/SKILL.md`, `references/pitfalls.md`, `scripts/sync-refs.sh`; `.claude/skills/todo-md/SKILL.md`
- async v0.22.5: `examples/curl/{main.mbt,moon.pkg}`, `src/http/pkg.generated.mbti`, `src/http/request.mbt` (get/request; no redirects), `src/io/pkg.generated.mbti` (`&Data::text`), `src/integration.mbt` (main error -> eprintln + exit 1)
- core (~/.moon/lib/core): `diff/pkg.generated.mbti`, `diff/README.mbt.md`, `diff/hunk.mbt`, `argparse/pkg.generated.mbti`, `string/pkg.generated.mbti` (`parse_int`); `moon ide doc "@argparse.Command"`, `moon ide doc String::split`
- moonbit-docs `next/language/error-handling.md` (try/catch)
- Go blog: `go/examples/blog/main.go`, `internal/site/server.go`, `repodocs/repodocs.go`

## What went wrong / notes

- First Go run served no documents: `repodocs/files` is filled by `go generate ./...`; re-ran after generating (documented in README).
- The first CLI run hit "Connection refused" after 2 paths: wrangler had hot-reloaded because I edited `worker/moon.pkg`, then logged "The Workers runtime crashed unexpectedly and is being restarted". After restarting `make dev`, curl and the CLI worked repeatedly; not reproduced, so not recorded as a bug.
- My first hand-written expectations for two diff tests miscounted hunks; fixed the expectations (output was correct).
- `moon check` flagged deprecated `StringView::to_string` (-> `to_owned`) and core/string used without import; `moon fmt` rewrote `Int` to `Int32` and the moon.pkg comment layout.
- The failure line on stderr is `Failure(compare/cmd/main.mbt:71:5-71:29@podhmo/blog FAILED: 6 of 6 paths differ)` (async prints the raised error); cosmetic only.
