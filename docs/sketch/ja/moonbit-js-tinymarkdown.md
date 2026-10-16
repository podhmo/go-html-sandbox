# 探索メモ: ts 版のブログで、tinymarkdown を TS で書かずに MoonBit の js ビルドで済ませる

ts 版のブログ（`ts/`）は、`go/pkg/tinymarkdown` を TS に移した `ts/pkg/tinymarkdown` で Markdown を読んでいた。この移植を持たずに、`moonbit/pkg/tinymarkdown` を **js ターゲットでビルドしたもの**をそのまま使えるかを確かめ、そのとおりに替えた記録（2026-10-17）。

調べたのは js ビルドそのもので、Wasm ではない。

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. TS の移植なしで、TS から型付きで使えるか | **使える** | MoonBit 側（`moonbit/pkg/tinymarkdown/js`）で、TS の型と同じ形の JS オブジェクトを組んで返す。`ts/` の型はそのまま残し、実装だけ `tinymarkdown.mjs` からの再 export にした。置き換えた時点で、`npm run check`（vitest 146 件と `tsc --noEmit`）が通った |
| 2. ブログが同じ HTML を返すか | **返す** | 替える前と後を `vite build` し、`wrangler dev` で配って全ページを比べた。49 パスで差分なし |
| 3. 代わりに払うもの: 大きさ | Worker のバンドルが **+64 KB（gzip で +9 KB）** | `vite build` の出力。446.95 KB → 510.57 KB、gzip で 138.74 KB → 148.12 KB |
| 4. 代わりに払うもの: 速さ | parse が **約 4 倍遅い** | Node 24 で、記事と文書 22 本（279 KiB）を解析。TS の移植 0.60 ms、MoonBit 2.46 ms（ウォーム） |

## 結論

- **TS の移植は要らない。** MoonBit の js ビルドに TS の型を付けるだけで、ブログのコードは変えずに動き、出力も同じ。Markdown の解析の実装は MoonBit の 1 つになり、TS 側に残るのは型の定義だけ。tinymarkdown のテスト（Go のテストケースを TS に移したもの）も、MoonBit 側のテストと重なるので消した。JS オブジェクトの形は `moonbit/pkg/tinymarkdown/js` のテストで見る。
- **払うのは、バンドルの gzip で 9 KB と、起動時の解析の 2 ms 弱。** ts 版は isolate の起動時に全部の文章を解析するので、この差は起動時間に乗る。本番での起動時間はまだ測っていない（`blog-ts` は TS の移植のままデプロイされている）。
- **生成した JS はコミットする。** `ts/` の作業に moon を要らないようにするため。MoonBit 側を直したら `moonbit/` で `make ts` を走らせる。忘れると `make check` が落ちる。
- **tinyfrontmatter は同じようにはできなかった。** MoonBit の `Map` が読み込みのときに乱数を使うので、workerd で Worker が起動しない（[下](#tinyfrontmatter-は同じようにできるか)）。

## 形

- `moonbit/pkg/tinymarkdown/js/js.mbt`: `parse(src) -> Js` と `inlines(s) -> Js`。`@tinymarkdown` の結果をたどり、`{ kind: "section", level, title, children }` のような JS オブジェクトを `extern "js"` の小さな関数（`{}` を作る、キーに値を入れる、配列に push する）で組む。`supported_targets = "+js"` なので、wasm-gc と native の `moon check` には入らない。テストは `moon test --target js` で、`JSON.stringify` した結果を見る（`make test` に入れた）。
- `moonbit/Makefile` の `ts`: `moon build --target js --release pkg/tinymarkdown/js` の出力を `ts/pkg/tinymarkdown/tinymarkdown.mjs` に写す。`make check` は最後に `make ts` を走らせ、差分があれば落ちる（`.mbti` と同じやり方）。
- `ts/pkg/tinymarkdown/tinymarkdown.ts`: 型（`Document`、`Block`、`Inline` など）と、`export { inlines, parse } from "./tinymarkdown.mjs"`。
- `ts/pkg/tinymarkdown/tinymarkdown.d.mts`: `tinymarkdown.mjs` の型。moon が生成する `.d.ts` は戻り値が `any` なので、手で書いた。moon 0.1.20261012 の `.d.ts` で型が付くのは `String`、`Int`、`Double`、`Bool`、`T?`（`T | undefined`）と関数だけで、`Array`、`struct`、`enum`、`#external type` は `any` になる。型を指定する方法も見当たらなかった。

`.mbti` から `.d.ts` を作る [mizchi/mbts](https://mooncakes.io/docs/mizchi/mbts)（0.0.3、最後のコミットは 2025-12-21）もある。これを使っても、MoonBit 側で JS オブジェクトを組む部分は省けない。値の形を moon 0.1.20261012 の js ビルドで確かめると、次のようだった。

| MoonBit の型 | mbts が付ける型 | 実際の値 |
| --- | --- | --- |
| `Array[T]` | `Array<T>` | JS の配列。合っている |
| `struct` | フィールドを持つ interface | フィールドを持つオブジェクト。合っている |
| `enum` | `$tag` がケースの名前、中身が `$0`、`$1` | `$tag` は数（`0`、`1`）、中身は `_0`、`_1`。合わない |
| `Map[K, V]` | JS の `Map<K, V>` | MoonBit のハッシュ表のオブジェクト（`entries`、`size` などを持つ）。合わない |

tinymarkdown の `Block` と `Inline` は enum なので、型が合わない。仮に合っていたとしても、ブログのコードは `kind: "section"` で分けているので、`$tag` の数で分けるように書き直すことになる。

MoonBit の js ビルドでは、`String` は JS の文字列、`Int` は JS の数になる。enum は、ケースごとのクラスに `$tag` と `_0`、`_1` のようなフィールドを持たせた形になる。そのままでは TS の `kind` で分ける型にならないので、MoonBit 側で JS オブジェクトを組んだ。

## 問いごとの結果

替える前に、TS の移植を残したまま、Vite のプラグインで import 先だけを MoonBit 版に替える spike で確かめた（コミット `4f1eb12` の `moonbit/experiments/js-tinymarkdown`。置き換えたあとに消した）。表の 1 と 2 は置き換えたあとにも確かめ直した。

### 1. 型付きで使えるか

spike では、`build/tinymarkdown.mjs` を空の結果を返すものに替えると 95 件が落ち、元に戻すと 146 件が通った。差し替えが実際に効いていることの確認。置き換えたあとは、`ts/` の vitest 146 件と `tsc --noEmit` が通った。その後 tinymarkdown のテストを消したので、今の `ts/` に残るのはブログのテストだけ。Node 24 から `tinymarkdown.ts` を直接 import しても動く。

### 2. ブログが同じ HTML を返すか

置き換える前の `ts/pkg/tinymarkdown/tinymarkdown.ts` に戻してビルドしたものと、置き換えたあとのものを `wrangler dev` で配った。`/`、`/docs/`、存在しないページから、たどれる記事と文書を全部取って比べ、49 パスでステータスも本文も同じだった。workerd の中でも動いている。

### 3. 大きさ

| | 大きさ | gzip |
| --- | --- | --- |
| ブログのバンドル（TS の移植） | 446.95 KB | 138.74 KB |
| ブログのバンドル（MoonBit の js ビルド） | 510.57 KB | 148.12 KB |
| tinymarkdown だけ、TS の移植（esbuild で minify） | 3,452 B | 1,388 B |
| tinymarkdown だけ、MoonBit の js ビルド（esbuild で minify） | 20,898 B | 6,241 B |

ブログのバンドルは Vite の既定のまま（Worker 向けは minify しない）。MoonBit の js ビルドには、文字列や配列の実装など core の一部が入る。tinymarkdown だけの行は spike のときのもの。

### 4. 速さ

spike の `bench.mjs` の結果（Node 24.21、Apple Silicon（arm64）の Mac。ウォームは 20 回回してから 50 回の平均）。対象は `posts/*.md`、`TODO.md`、`docs/**/*.md` の 22 本、279 KiB と、そこに含まれる段落と見出し 573 個。両方の結果が同じであることも確かめた。

| | 初回 | ウォーム |
| --- | --- | --- |
| TS の移植の `parse` | 0.86 ms | 0.60 ms |
| MoonBit の `parse` | 3.30 ms | 2.46 ms |
| MoonBit の解析だけ（JS オブジェクトを組まない） | 2.61 ms | 2.42 ms |
| TS の移植の `inlines` | 0.67 ms | 0.16 ms |
| MoonBit の `inlines` | 0.40 ms | 0.27 ms |

解析だけでもほぼ同じ時間がかかるので、遅いのは JS オブジェクトを組むところではなく、MoonBit の解析そのもの。どこが遅いか（行の分割や文字列の組み立てなど）は調べていない。

## tinyfrontmatter は同じようにできるか

**できなかった。** 同じ形で `moonbit/pkg/tinyfrontmatter/js` を作り、`ts/pkg/tinyfrontmatter` を置き換えてみた（2026-10-17、コミットはしていない）。Node の vitest は通ったが、`wrangler dev` では Worker が起動しなかったので戻した。`ts/pkg/tinyfrontmatter` は TS の移植のまま。

- **workerd で起動しない。** `@tinyfrontmatter.split` は `Map` を返す。`Map` を使うと、MoonBit の core のハッシュのシードを作るコードが入る。このコードはモジュールのトップレベルで `crypto.getRandomValues` を呼ぶ（生成された JS の `const _M0FPB4seed = _M0FPB12random__seed();`）。workerd はグローバルスコープでの乱数の生成を禁じているので、`Disallowed operation called within global scope` で止まる。Node では止まらないので、vitest では気づけない。tinymarkdown は `Map` を使わないので、このコードは入らない。
- **core の実装は共有されない。** `.mjs` はパッケージごとに、MoonBit の core のうち使う部分を抱える。38 行の TS の移植を置き換えるだけで、ブログのバンドルが 511.15 KB → 557.12 KB、gzip で 148.37 KB → 155.98 KB 増えた。

MoonBit の js ビルドを Worker で使うなら、`Map` のようにトップレベルで乱数を使う core の機能を避けるか、`wrangler dev` で起動まで確かめる必要がある。
