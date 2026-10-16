# 探索メモ: 素直に Workers で書くと、どれだけ楽か

Go 版と MoonBit 版のブログは、どちらも Wasm として Cloudflare Workers で動かしている。そのために、JS と Wasm の間の受け渡し（アダプター、線形メモリの ABI）、記事を埋め込むスクリプト、wasm-opt、Makefile を自分で用意してきた。では、Wasm を使わず、Workers で普通に使われる TypeScript と [Hono](https://hono.dev/) でそのまま書くと、どれだけ楽になるのか（2026-10-17）。

実装は `ts/`（[README](../../../ts/README.md)）に置いた。方針は「素直に」で、Hono のガイドに書いてある形から外れないようにした。最終的には [Cloudflare Workers + Vite](https://hono.dev/docs/getting-started/cloudflare-workers-vite) のテンプレート（`cloudflare-workers+vite`）の形にした。最初は [wrangler だけのガイド](https://hono.dev/docs/getting-started/cloudflare-workers)の形で書いたので、その版（コミット `95bf1d5`）とも比べる。

## 何を確かめたか

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. 移植が要るのは tinymarkdown だけで、残りは Hono 周りで済むか | **済む**。移植したのは tinymarkdown と tinyfrontmatter（38 行）だけ | `el` と `picoel` は移植せず、ページは hono/jsx の TSX で書いた。Go のテストケースを vitest に移し、115 件が通る |
| 2. Go 版と同じページを返せるか | **書き方の違いを除けば同じ**。30 パスのうち 29 パスが一致 | `vite build` したものを `vite preview` で動かし、Go 版と同じ BASE_URL で、全記事・全文書のページを取って比べた（下の「Go 版との差」） |
| 3. 書くコードはどれだけ減るか | **アプリは Go 版の約 6 割。ライブラリは 3 分の 1、Workers との糊は 55 行** | 下の「コードの量」の表。テストを除いた行数 |
| 4. Workers と Vite の何が、自分で書かずに済んだか | **ルーティング、HEAD、静的ファイル、JS と Wasm の受け渡し、記事の埋め込み、ビルドの糊** | 下の「書かずに済んだもの」 |
| 5. 大きさはどうか | **アップロードは 423 KiB（gzip 後 131 KiB）**。ほとんどは埋め込んだ文章で、Hono とアプリは数十 KB | `wrangler deploy --dry-run` と、esbuild の metafile |
| 6. Node 24 なら TypeScript をそのまま使えるか | **`.ts` は使える。`.tsx` は使えない**。Vite の構成では、どちらも Node で直接は動かさなくなった | Node から `pkg/tinymarkdown/tinymarkdown.ts` を import すると動く。`node src/app.tsx` は `ERR_UNKNOWN_FILE_EXTENSION` |

デプロイはしていないので、本番での起動時間は測っていない。

## 結論

- **楽になった。** JS と Wasm の境界にまつわる仕事（アダプター、ABI、wasm-opt、埋め込みのシェルスクリプト、Makefile）が丸ごと要らなくなった。Vite の構成では、記事を埋め込むスクリプトも要らない。Workers との糊は、`vite.config.ts`（16 行）、`wrangler.jsonc`（14 行）、`import.meta.glob` で記事と文書を読む `sources.ts`（25 行）だけ。
- **自分で書く必要が残ったのは、ブログ固有のところだけ。** Markdown の解析（独自の小さな方言なので、既存のライブラリでは置き換えにくい）、記事の検査、リンクの解決、ページの見た目。
- **大きさは Wasm 版より小さくはないが、困るほどでもない。** 大きさのほとんどは埋め込んだ文章で、コードは数十 KB。

## Go 版との差

ts 版と Go 版（`go run ./examples/blog`）を、どちらも同じ BASE_URL で起動した。MoonBit 版の `make compare` で比べると、6 パスのうち 5 パスで本文が違った。違いはどれも HTML の書き方で、意味は同じ。

| 違い | Go 版（`el`） | ts 版（hono/jsx） |
| --- | --- | --- |
| doctype | `<!doctype html>` と改行 | `<!DOCTYPE html>`（`jsxRenderer` が書く） |
| void 要素 | `<meta charset="utf-8">` | `<meta charset="utf-8"/>` |
| `"` のエスケープ | `&#34;`（Go の `html.EscapeString`） | `&quot;` |
| `Content-Type` | `text/html; charset=utf-8` | `text/html; charset=UTF-8`（Hono の `c.html`） |
| `site.css` と favicon の URL | `/site.css?v=5c6cac07`、`/favicon.svg` | `/assets/site-BmG3ebL8.css`、`/assets/favicon-fHqwAk8h.svg`（Vite が名前にハッシュを付ける） |

本文の違いをそろえてから（`Content-Type` は比べずに）、トップ、`/docs/`、そこからリンクされている全記事と全文書、`.md` のソース、404 のページを比べた（30 パス）。違ったのは `/docs` のリダイレクトだけで、ステータス（307）と行き先は同じ。Go の `http.Redirect` は短い HTML の本文を付けるが、Hono の `c.redirect` は付けない。wrangler だけの版でも、同じ比べ方で同じ結果だった。

ほかに、次の違いがある。

- Go 版は `//posts/hello` のような重なったスラッシュを詰めてリダイレクトするが、ts 版は 404 を返す。`..` を含むパスは workerd が先に正規化するので、Worker まで届かない（[MoonBit の調査メモ](moonbit-workers-wasm.md)にもある挙動）。
- Go 版にある `/favicon.svg` という固定のパスがない。ページはハッシュ付きの URL を指すので表示は変わらないが、`/favicon.svg` を直接取ると 404 になる。
- `site.css` は Vite が minify するので、2,286 B が 722 B になった。

## コードの量

テストを除いた行数。Go 版は `-watch`（`livereload.go`）と `main.go` を除いた、ページを返すところだけ。

| | Go | MoonBit | ts |
| --- | --- | --- | --- |
| アプリ（ルーティング、ページ、記事の読み込み、リンク） | 833 | 1,121 | 490（`app.tsx`、`views.tsx`、`content.ts`、`links.ts`） |
| ライブラリ | 1,084（`el`、`picoel`、`tinymarkdown`、`tinyfrontmatter`） | 2,205（左に加えて `http`、`http/wasm`） | 344（`tinymarkdown`、`tinyfrontmatter`） |
| Workers との糊 | `workers/`（syumai/workers-go） | 309（`adapter.mjs`、`worker.mjs`、`worker.mbt`、埋め込みのシェルスクリプト）と Makefile | 55（`sources.ts`、`vite.config.ts`、`wrangler.jsonc`） |

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
- **記事と文書の埋め込み**：`import.meta.glob(["…/TODO.md", "…/docs/**/*.md"], { query: "?raw", eager: true })` で、ファイルの一覧と中身がそのまま手に入る。Go 版の `go generate` によるコピー、MoonBit 版の `embed.sh` に当たるものがない。
- **静的ファイル**：`site.css` と `favicon.svg` は `?url` で import するだけで、Vite がハッシュ付きの名前で `dist/client/assets/` に出し、Workers の Static Assets になる。Worker が動く前に返されるので、ルートも要らない。長いキャッシュは `public/_headers` に書くだけで付いた。Go 版の `site.css` のハッシュの計算もない。
- **JS と Wasm の受け渡し**：なし。`BASE_URL` は `c.env` から読むだけ。
- **開発サーバー**：`vite` が Worker を workerd で動かす。記事や `TODO.md` を書き換えると、次のリクエストから反映される（確かめた）。
- **ビルドとデプロイ**：`vite build` が Worker と静的ファイルを `dist/` に出し、デプロイ用の `wrangler.json` も書く。`wrangler deploy` はそれを自動で見つける。wasm-opt も Makefile も要らない。
- **テスト**：Hono のガイドどおり `app.request(path, init, env)` で呼ぶだけ。vitest は Vite の上で動くので、`import.meta.glob` と `?url` もテストの中でそのまま動く。Workers のランタイムを立ち上げずに、29 件のアプリのテストが 0.2 秒ほどで終わる。

## 素直にいかなかったところ

- **Vite は、既定ではプロジェクトの外のファイルを読まない。** 記事と文書と `site.css` はリポジトリのルートにあるので、`server.fs.allow` にリポジトリのルートを足した。
- **小さい favicon は data: URL になる。** Vite は 4 KB 未満のファイルをページに埋め込むので、`build.assetsInlineLimit: 0` にした。
- **`.tsx` は Node で動かない。** Node 24 の型の除去は JSX を変換しないので、TSX を読み込むテストは `node --test` では走らない。Vite の構成では vitest を使うのが自然なので、困らない。`tsconfig.json` は `allowImportingTsExtensions` と `erasableSyntaxOnly` を有効にしたままにして、`.ts` は Node でも動く形にしている。
- **npm が esbuild と workerd の postinstall を止める。** `npm install` で警告が出るが、プラットフォームごとのバイナリは optional dependency として入るので、そのまま動いた。

wrangler だけの版（`95bf1d5`）では、ほかにも次のことがあった。どれも Vite の構成で消えた。

- 記事と文書を JSON に書き出すスクリプト（31 行）を、wrangler の `build.command` で走らせていた。`build.command` は wrangler を起動したディレクトリで走る（設定ファイルのディレクトリではない）。
- `build.watch_dir` はディレクトリしか指定できず、リポジトリのルートを見るとスクリプトの出力も見てしまうので、`TODO.md` の変更を拾えなかった。
- esbuild が JSON の中の日本語を `\uXXXX` に書き換えるので、273 KB の JSON がバンドルの中では 442 KB に膨らんだ。Vite（Rolldown）の出力は UTF-8 のままで、`\uXXXX` は 0 件。

## 大きさ

記事 8 本と文書 14 本（`TODO.md`、`docs/**/*.md`）を埋め込んだ大きさ。

| 構成 | アップロード | gzip 後 |
| --- | --- | --- |
| Vite（テンプレートどおり、minify なし） | 423.27 KiB | 130.80 KiB |
| Vite（`vite build --minify`） | 334.84 KiB | 114.41 KiB |
| wrangler だけ（`--minify`、`95bf1d5`） | 495.12 KiB | 124.29 KiB |

wrangler だけの版で esbuild の metafile を見ると、Hono（hono/jsx を含む）が 48 KB、アプリと tinymarkdown が 12 KB ほど。埋め込んだ文章を除いたコードは、minify 後で 59,814 B、gzip 後 23,102 B だった。

比べる相手として、MoonBit 版の記録（[調査メモ](moonbit-workers-wasm.md)）は 237.41 KiB（gzip 後 78.50 KiB）で、これは記事 4 本と文書 7 本のとき。埋め込んだ文章の量が違うので、そのままは比べられない。

## 速さ

wrangler だけの版を `wrangler dev` で動かし、`curl` で 20 回送った往復時間の中央値。参考に、ネイティブで動く Go 版（`go run`）も並べた。

| パス | 大きさ | ts（`wrangler dev`） | Go（ネイティブ） |
| --- | --- | --- | --- |
| `/` | 2,492 B | 2.1 ms | 0.4 ms |
| `/docs/sketch/ja/moonbit-workers-wasm` | 51,977 B | 2.2 ms | 0.6 ms |
| `/docs/sketch/ja/moonbit-modernize` | 67,979 B | 2.5 ms | 0.7 ms |

ts 版は、記事と文書を isolate の起動時に一度だけ解析し、リクエストごとには TSX を文字列にするだけ。大きいページでも `/` との差は 0.5 ms 以内で、Workers の無料プランの CPU 時間の上限（10 ms）に比べて十分小さい。

## この先に考えること

- 本番にデプロイして、起動時間を MoonBit 版と比べる。
- 文章を Worker のバンドルから外すなら、Static Assets に置いて `env.ASSETS.fetch` で読む。ts 版はハンドラーが非同期なので、MoonBit 版の TODO にある「文章を Wasm にどう渡すか」に当たる問題は起きない。
