# 探索メモ: 素直に Workers で書くと、どれだけ楽か

Go 版と MoonBit 版のブログは、どちらも Wasm として Cloudflare Workers で動かしている。そのために、JS と Wasm の間の受け渡し（アダプター、線形メモリの ABI）、記事を埋め込むスクリプト、wasm-opt、Makefile を自分で用意してきた。では、Wasm を使わず、Workers で普通に使われる TypeScript と [Hono](https://hono.dev/) でそのまま書くと、どれだけ楽になるのか（2026-10-17）。

実装は `ts/`（[README](../../../ts/README.md)）に置いた。方針は「素直に」で、Hono の [Cloudflare Workers のガイド](https://hono.dev/docs/getting-started/cloudflare-workers)と [JSX のガイド](https://hono.dev/docs/guides/jsx)に書いてある形から外れないようにした。

## 何を確かめたか

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. 移植が要るのは tinymarkdown だけで、残りは Hono 周りで済むか | **済む**。移植したのは tinymarkdown と tinyfrontmatter（38 行）だけ | `el` と `picoel` は移植せず、ページは hono/jsx の TSX で書いた。Go のテストケースを vitest に移し、115 件が通る |
| 2. Go 版と同じページを返せるか | **書き方の違いを除けば同じ**。29 パスのうち 28 パスが一致 | `wrangler dev` と Go 版を同じ BASE_URL で起動し、全記事・全文書のページを取って比べた（下の「Go 版との差」） |
| 3. 書くコードはどれだけ減るか | **アプリは Go 版の約 6 割、ライブラリと糊は 3 分の 1 以下** | 下の「コードの量」の表。テストを除いた行数 |
| 4. Workers の何が、自分で書かずに済んだか | **ルーティング、HEAD、静的ファイル、JS と Wasm の受け渡し、ビルドの糊** | 下の「書かずに済んだもの」 |
| 5. 大きさはどうか | **アップロードは 495 KiB（gzip 後 124 KiB）**。コードは 60 KB（同 23 KB）で、残りは埋め込んだ文章 | `wrangler deploy --dry-run --minify` と、esbuild の metafile |
| 6. Node 24 なら TypeScript をそのまま使えるか | **`.ts` は使える。`.tsx` は使えない** | `node scripts/embed.ts` は動く。`node src/app.tsx` は `ERR_UNKNOWN_FILE_EXTENSION` |

デプロイはしていないので、本番での起動時間は測っていない。

## 結論

- **楽になった。** JS と Wasm の境界にまつわる仕事（アダプター、ABI、wasm-opt、埋め込みのシェルスクリプト、Makefile）が丸ごと要らなくなった。残った糊は、記事を JSON に書き出す 31 行のスクリプトと、23 行の `wrangler.jsonc` だけ。
- **自分で書く必要が残ったのは、ブログ固有のところだけ。** Markdown の解析（独自の小さな方言なので既存のライブラリでは置き換えにくい）、記事の検査、リンクの解決、ページの見た目。
- **大きさは、Wasm 版より小さくはない。** コードは 23 KB（gzip 後）と小さいが、esbuild が JSON の中の日本語を `\uXXXX` に書き換えるので、文章の分が約 1.6 倍に膨らむ。

## Go 版との差

`ts/` の Worker（`wrangler dev`）と Go 版（`go run ./examples/blog`）を、どちらも `BASE_URL` を `https://blog.podhmo.workers.dev` にして起動した。MoonBit 版の `make compare` で比べると、6 パスのうち 5 パスで本文が違った。違いはどれも HTML の書き方で、意味は同じ。

| 違い | Go 版（`el`） | ts 版（hono/jsx） |
| --- | --- | --- |
| doctype | `<!doctype html>` と改行 | `<!DOCTYPE html>`（`jsxRenderer` が書く） |
| void 要素 | `<meta charset="utf-8">` | `<meta charset="utf-8"/>` |
| `"` のエスケープ | `&#34;`（Go の `html.EscapeString`） | `&quot;` |
| `Content-Type` | `text/html; charset=utf-8` | `text/html; charset=UTF-8`（Hono の `c.html`） |

本文の 3 つの違いをそろえてから（`Content-Type` は比べずに）、トップ、`/docs/`、そこからリンクされている全記事と全文書、`.md` のソース、404 のページを比べた（29 パス）。違ったのは `/docs` のリダイレクトだけで、ステータス（307）と行き先は同じ。Go の `http.Redirect` は短い HTML の本文を付けるが、Hono の `c.redirect` は付けない。

Go 版がしていて ts 版がしていないこととして、`//posts/hello` のような重なったスラッシュを詰めるリダイレクトがある。ts 版は 404 を返す。`..` を含むパスは workerd が先に正規化するので、Worker まで届かない（[MoonBit の調査メモ](moonbit-workers-wasm.md)にもある挙動）。

## コードの量

テストを除いた行数。Go 版は `-watch`（`livereload.go`）と `main.go` を除いた、ページを返すところだけ。

| | Go | MoonBit | ts |
| --- | --- | --- | --- |
| アプリ（ルーティング、ページ、記事の読み込み、リンク） | 833 | 1,121 | 490（`app.tsx`、`views.tsx`、`content.ts`、`links.ts`） |
| ライブラリ | 1,084（`el`、`picoel`、`tinymarkdown`、`tinyfrontmatter`） | 2,205（左に加えて `http`、`http/wasm`） | 344（`tinymarkdown`、`tinyfrontmatter`） |
| Workers との糊 | `workers/`（syumai/workers-go） | 309（`adapter.mjs`、`worker.mjs`、`worker.mbt`、埋め込みのシェルスクリプト）と Makefile | 54（`embed.ts`、`wrangler.jsonc`） |

ts 版のアプリが短いのは、ページを TSX でそのまま書けるので、`picoel` の関数を呼んで木を組み立てる分がないため。たとえば記事の一覧は、HTML の形がそのまま見える。

```tsx
<article>
  <hgroup>
    <h2><a href={postPath(p)}><Inlines text={p.title} link={noLinks} /></a></h2>
    <p><time datetime={p.date}>{p.date}</time></p>
  </hgroup>
</article>
```

## 書かずに済んだもの

- **ルーティング**：`app.get("/posts/:slug", ...)`、`app.get("/docs/:path{.+}", ...)` だけ。GET のルートは HEAD にも答え、ほかのメソッドは `app.notFound` の 404 になる。Go 版は TinyGo の `net/http` に合わせて手で振り分け、MoonBit 版は `http` の `Router` を自分で書いた。
- **共通のレイアウト**：`jsxRenderer` に一度書き、各ページは `c.render(本文, メタ情報)` で返す。メタ情報の型は `ContextRenderer` を拡張して付けた。
- **エスケープ**：hono/jsx が文字列をすべてエスケープするので、記事の中の `<b>` はテキストのまま出る（テストで確かめている）。
- **静的ファイル**：`site.css` と `favicon.svg` は、`wrangler.jsonc` の `assets` で Workers の Static Assets にした。Worker が動く前に返されるので、ルートも要らない。Go 版と同じ `Cache-Control` は `public/_headers` に書くだけで付いた。
- **JS と Wasm の受け渡し**：なし。`env.BASE_URL` は `c.env` から読むだけ。
- **ビルド**：wrangler が esbuild で TSX をバンドルする。`build.command` で埋め込みのスクリプトを走らせ、`build.watch_dir` で記事と文書の変更を拾う。wasm-opt も Makefile も要らない。
- **テスト**：Hono のガイドどおり `app.request(path, init, env)` で呼ぶだけ。Workers のランタイムを立ち上げずに、29 件のアプリのテストが 0.2 秒ほどで終わる。

## 素直にいかなかったところ

- **`.tsx` は Node で動かない。** Node 24 の型の除去は JSX を変換しないので、TSX を読み込むテストは `node --test` では走らない。テストは vitest にした。ライブラリと埋め込みのスクリプトは `.ts` なので、`node scripts/embed.ts` のようにそのまま動く。そのため `tsconfig.json` で `allowImportingTsExtensions` と `erasableSyntaxOnly` を有効にし、import には `.ts` を書いている。
- **wrangler の `build.command` は、wrangler を起動したディレクトリで走る。** 設定ファイルのディレクトリではない。npm scripts で `cd examples/blog && wrangler dev` にした（MoonBit 版の Makefile も同じ形）。
- **`TODO.md` の変更は `wrangler dev` で拾えない。** `build.watch_dir` はディレクトリしか指定できず、リポジトリのルートを見ると、スクリプトの出力（`ts/` の下）も見てしまう。
- **`wrangler deploy --dry-run` もビルドを走らせる。** 埋め込みを差し替えて大きさを測ろうとしたら、上書きされた。コードだけの大きさは esbuild で直接測った。
- **npm が esbuild と workerd の postinstall を止める。** `npm install` で警告が出るが、プラットフォームごとのバイナリは optional dependency として入るので、`wrangler dev` はそのまま動いた。

## 大きさ

`wrangler deploy --dry-run --minify` の結果は 495.12 KiB（gzip 後 124.29 KiB）。記事 8 本と文書 13 本（`TODO.md`、`docs/**/*.md`）を埋め込んだ大きさ。

esbuild の metafile で内訳を見ると、文章の JSON が 442 KB、Hono（hono/jsx を含む）が 48 KB、ほかが 12 KB ほど。JSON の元のファイルは 273 KB だが、esbuild が ASCII でない文字を `\uXXXX` にするので、日本語の 1 文字（UTF-8 で 3 バイト）が 6 バイトになる。埋め込んだ文章を除くと、minify 後で 59,814 B、gzip 後 23,102 B。

比べる相手として、MoonBit 版の記録（[調査メモ](moonbit-workers-wasm.md)）は 237.41 KiB（gzip 後 78.50 KiB）で、これは記事 4 本と文書 7 本のとき。埋め込んだ文章の量が違うので、そのままは比べられない。

## 速さ

`wrangler dev` に `curl` で 20 回送った往復時間の中央値。参考に、ネイティブで動く Go 版（`go run`）も並べた。

| パス | 大きさ | ts（`wrangler dev`） | Go（ネイティブ） |
| --- | --- | --- | --- |
| `/` | 2,492 B | 2.1 ms | 0.4 ms |
| `/docs/sketch/ja/moonbit-workers-wasm` | 51,977 B | 2.2 ms | 0.6 ms |
| `/docs/sketch/ja/moonbit-modernize` | 67,979 B | 2.5 ms | 0.7 ms |

ts 版は、記事と文書を isolate の起動時に一度だけ解析し、リクエストごとには TSX を文字列にするだけ。大きいページでも `/` との差は 0.5 ms 以内で、Workers の無料プランの CPU 時間の上限（10 ms）に比べて十分小さい。

## この先に考えること

- 文章の `\uXXXX` を避けるなら、JSON ではなく wrangler の `Text` モジュール（`rules`）で `.md` を取り込むか、Static Assets に置いて `env.ASSETS.fetch` で読む。ts 版はハンドラーが非同期なので、MoonBit 版の TODO にある「文章を Wasm にどう渡すか」に当たる問題は起きない。
- 本番にデプロイして、起動時間を MoonBit 版と比べる。
