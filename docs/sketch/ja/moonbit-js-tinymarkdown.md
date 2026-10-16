# 探索メモ: MoonBit の tinymarkdown を js にビルドして、ts 版のブログで使う

ts 版のブログ（`ts/`）は、`go/pkg/tinymarkdown` を TS に移した `ts/pkg/tinymarkdown` で Markdown を読んでいる。この TS の移植の代わりに、MoonBit の `tinymarkdown` を **js ターゲットでビルドしたもの**を使えるかを確かめた記録（2026-10-17）。
spike は `moonbit/experiments/js-tinymarkdown` に置いた。

ここで調べたのは js ビルドそのもので、Wasm ではない。比べる相手は TS の移植。

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. TS の型のまま使えるか | **使える** | MoonBit 側で、TS の型と同じ形の JS オブジェクトを組んで返す。`ts/` のテスト 146 件（tinymarkdown の移植のテストとブログのテスト）が、import 先を差し替えても全部通る |
| 2. ブログが同じ HTML を返すか | **返す** | 両方を `vite build` し、`wrangler dev` で配って全ページを比べた。47 パスで差分なし |
| 3. 大きさはどれだけ増えるか | Worker のバンドルで **+63 KB（gzip で +9 KB）** | `vite build` の出力。440.14 KB → 502.94 KB、gzip で 136.64 KB → 146.02 KB |
| 4. 速さはどうか | parse が **約 4 倍遅い** | Node 24 で、記事と文書 22 本（279 KiB）を解析。TS 0.60 ms、MoonBit 2.46 ms（ウォーム） |

## 結論

- **差し替えはできる。** MoonBit の `parse` と `inlines` を js にビルドし、TS の型を付けた薄いファイルを置けば、ブログのコードは 1 行も変えずに動く。出力も TS の移植と同じ。
- **ただし、ts 版のブログで使う理由はない。** バンドルが gzip で 9 KB 増え、parse は 4 倍遅い。ts 版は起動時に全部の文章を解析するので、この 2 ms 弱は起動時間にそのまま乗る。TS の移植は 3.5 KB（minify 後）で済んでいる。
- 得られるのは「Markdown の解析の実装が 1 つで済む」ことだけ。ts 版は Go 版や MoonBit 版と比べるために置いているので、その目的にも合わない。

## spike の形

`moonbit/experiments/js-tinymarkdown` は、ほかの experiments と同じく独立したモジュールで、`moon.work` でブログのモジュール（`../..`）を読む。`extern "js"` を使うので、`moon.mod` の `preferred_target` は `js`。

- `lib/lib.mbt`: `parse(src) -> Js` と `inlines(s) -> Js`。`@tinymarkdown` の結果をたどり、`{ kind: "section", level, title, children }` のような JS オブジェクトを `extern "js"` の小さな関数（`{}` を作る、キーに値を入れる、配列に push する）で組む。`parse_only` は解析だけして捨てる計測用。
- `lib/moon.pkg`: `"js": { "exports": [ "parse", "inlines", "parse_only" ], "format": "esm" }`。
- `tinymarkdown.ts`: `build/tinymarkdown.mjs` の `parse` と `inlines` に、TS の移植の型（`Document`、`Inline[]`）を付けて export する。型も TS の移植から `export type *` で再 export する。
- `swap.mjs`: Vite のプラグイン。import を解決した結果が `ts/pkg/tinymarkdown/tinymarkdown.ts` なら、上の `tinymarkdown.ts` に替える。テストの `./tinymarkdown.ts` のような相対の import も替わる。
- `vitest.config.mjs`、`vite.config.mjs`: `ts/` のテストと、ブログのビルド（`ts/examples/blog/vite.config.ts` を読み、プラグインを足し、出力先を `build/blog/` にする）。
- `bench.mjs`: 両方の結果が同じかを確かめてから、時間を測る。`crawl.mjs`: 2 つのブログの全ページを比べる。
- `Makefile`: `build`、`test`、`bench`、`build-blog`、`compare`。

## 問いごとの結果

### 1. TS の型のまま使えるか

MoonBit の js ビルドでは、`String` は JS の文字列、`Int` は JS の数になるが、enum は、ケースごとのクラスに `$tag` と `_0`、`_1` のようなフィールドを持たせた形になる（`build/tinymarkdown.mjs` の `Block` の `Section`）。そのままでは TS の `kind` で分ける型にならないので、MoonBit 側で JS オブジェクトを組んだ。生成される `lib.d.ts` では戻り値が `any` なので、型は `tinymarkdown.ts` で付ける。

差し替えが本当に効いているかは、`build/tinymarkdown.mjs` を空の結果を返すものに替えて確かめた。95 件が落ち、元に戻すと 146 件が通る。

### 2. ブログが同じ HTML を返すか

`make build-blog` で、TS の移植のままのもの（`ts/examples/blog/dist/`）と MoonBit 版（`build/blog/`）をビルドした。MoonBit 版のバンドルには TS の移植の関数（`parseInlines`）が入っていない。`make compare` で両方を `wrangler dev` で配り、`/`、`/docs/`、存在しないページから、たどれる記事と文書を全部取って比べた。47 パスで、ステータスも本文も同じ。workerd の中でも動いている。

### 3. 大きさ

| | 大きさ | gzip |
| --- | --- | --- |
| ブログのバンドル（TS の移植） | 440.14 KB | 136.64 KB |
| ブログのバンドル（MoonBit の js ビルド） | 502.94 KB | 146.02 KB |
| tinymarkdown だけ、TS の移植（esbuild で minify） | 3,452 B | 1,388 B |
| tinymarkdown だけ、MoonBit の js ビルド（esbuild で minify） | 20,898 B | 6,241 B |

ブログのバンドルは Vite の既定のまま（Worker 向けは minify しない）。MoonBit の js ビルドには、文字列や配列の実装など core の一部が入る。

### 4. 速さ

`make bench` の結果（Node 24.21、Apple Silicon（arm64）の Mac。ウォームは 20 回回してから 50 回の平均）。対象は `posts/*.md`、`TODO.md`、`docs/**/*.md` の 22 本、279 KiB と、そこに含まれる段落と見出し 573 個。

| | 初回 | ウォーム |
| --- | --- | --- |
| TS の移植の `parse` | 0.86 ms | 0.60 ms |
| MoonBit の `parse` | 3.30 ms | 2.46 ms |
| MoonBit の `parse_only`（JS オブジェクトを組まない） | 2.61 ms | 2.42 ms |
| TS の移植の `inlines` | 0.67 ms | 0.16 ms |
| MoonBit の `inlines` | 0.40 ms | 0.27 ms |

`parse` と `parse_only` がほぼ同じなので、遅いのは JS オブジェクトを組むところではなく、MoonBit の解析そのもの。どこが遅いか（行の分割や文字列の組み立てなど）は調べていない。
