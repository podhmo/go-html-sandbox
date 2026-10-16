# 探索メモ: MoonBit の tinymarkdown と el をブラウザーから呼ぶ

記事の編集ページのようなもの（今はない）で、入力中の Markdown を MoonBit の `tinymarkdown` で読み、`el` で HTML にしてその場でプレビューできるかを確かめた記録（2026-10-16）。
これまでの MoonBit 版は、Workers の上で Wasm が要求を受けて応答を返す形（[アダプターの探索メモ](moonbit-workers-http.md)）だけだった。サーバーを通さず、ブラウザーの JS から MoonBit の関数を直接呼べるかを見た。
spike は `moonbit/experiments/browser-render` に置いた。

## 結論

- **ブラウザーから直接呼べる。** `tinymarkdown`、`el`、`picoel` はホストに依存しない純粋な MoonBit なので、`render(md : String) -> String` を 1 つ export するパッケージを書けば、ページの JS から普通の関数として呼べる。
- **js と wasm-gc のどちらのターゲットでも動いた。** Node 24.21.0 と Chrome 155（headless）で、どちらも同じ HTML を返した。
  - js: ES module（`"format": "esm"`）。`import { render } from "./build/lib.mjs"` で呼ぶ。
  - wasm-gc: `"use-js-builtin-string": true` でビルドし、`WebAssembly.instantiateStreaming(fetch(...), {}, { builtins: ["js-string"], importedStringConstants: "_" })` でコンパイルすると、import が空になる。JS の文字列をそのまま渡し、そのまま受け取れる。Workers 版のような線形メモリを通した受け渡しは要らない。
- **Workers から配るだけなら、Worker 側には何も要らない。** Static Assets で `index.html`、`lib.wasm`、`lib.mjs` を配れば、描画はブラウザーで行われる。`wrangler dev --assets .` で確かめた。
- **Worker の中で `render` を呼ぶなら、今は js ビルドだけが動く。** wasm-gc ビルドは、workerd が import した Wasm を builtins なしでコンパイルするので、インスタンスを作れない（[調査メモ](moonbit-workers-wasm.md)と同じ問題）。

## spike の形

`moonbit/experiments/browser-render` は、ほかの experiments と同じく独立したモジュールで、`moon.work` でブログのモジュール（`../..`）を読む。

- `lib/lib.mbt`: `render`。`@tinymarkdown.parse` で読み、`picoel` で要素を組み、`@el.render_html` で文字列にする。
- `lib/moon.pkg`: 両方のターゲットの link 設定。

  ```moonbit
  options(
    link: {
      "js": { "exports": [ "render" ], "format": "esm" },
      "wasm-gc": { "exports": [ "render" ], "use-js-builtin-string": true },
    },
  )
  ```

- `index.html`: 左の textarea に入力するたびに `render` を呼び、右に `innerHTML` で表示する。js と wasm-gc を切り替えられ、1 回の描画にかかった時間を出す。
- `try.mjs`: Node で両方のビルドを呼んで出力を比べる。
- `Makefile`: `build`、`try`、`serve`（`python3 -m http.server`）、`dev`（`wrangler dev --assets .`）、`screenshot`（headless Chrome）。

`render` はブログの `render_blocks` と `render_inlines`（`moonbit/examples/blog/site/views.mbt`）を小さく写したもの。ブログのものは非公開なので使えなかった。見出しは h2 と h3 だけで、リンクの URL は検査しない。本文の文字はすべて `@picoel.text` を通るので、Markdown に書いた `<b>` はエスケープされ、出力を `innerHTML` に入れてよい。

## 試したこと

### 1. Node

`make try` で、同じ Markdown を両方のビルドに渡した。

```
js  : <article><section><h2>見出し</h2><p>本文 <code>code</code> と <a href="https://example.com">リンク</a> &lt;b&gt;esc&lt;/b&gt;</p><ul><li>a</li><li>b</li></ul></section></article>
imports: []
wasm: <article><section><h2>見出し</h2><p>本文 <code>code</code> と <a href="https://example.com">リンク</a> &lt;b&gt;esc&lt;/b&gt;</p><ul><li>a</li><li>b</li></ul></section></article>
```

`WebAssembly.Module.imports` が空なので、builtins を有効にしてコンパイルすれば、import オブジェクトを用意しなくてよい。

### 2. ブラウザー（Chrome 155、headless）

`make serve` で配ったページを `--dump-dom` と `--screenshot` で見た。wasm-gc ビルドで、見出し、コード、リンク、リスト、表が描画された。1 回の描画（`render` と `innerHTML` の代入）は 1.7〜5.5 ms だった。計ったのは数回だけで、ベンチマークではない。

### 3. Workers の Static Assets で配る

`make dev`（`wrangler dev --assets . --compatibility-date 2026-10-01`）で同じページを配り、Chrome で開いた。`.wasm` は `Content-Type: application/wasm` で返り、wasm-gc ビルドで描画された。Worker の JS は書いていない。

`--assets .` はディレクトリをまるごとアセットにするので、ローカルで確かめる用。そのまま deploy すると `_build` なども上がる。

### 4. Worker の中で呼ぶ

`/tmp` に置いた使い捨ての Worker で、両方のビルドを `import` して `render` を呼んだ（wrangler 4 の `wrangler dev`）。

- js ビルド: そのまま動き、HTML を返した。
- wasm-gc ビルド: `new WebAssembly.Instance(wasm, {})` が `TypeError: WebAssembly.Instance(): Import #0 "_": module is not an object or function` で失敗した。`WebAssembly.Module.imports` には、文字列リテラルの `_.<リテラル>`（global）と `wasm:js-string` の 6 関数（`length`、`charCodeAt`、`equals`、`concat`、`fromCodePoint`、`fromCharCodeArray`）が残っていた。

## サイズ

`moon build --release` の出力そのまま（wasm-opt なし）。

| ビルド | 大きさ |
| --- | --- |
| js（`lib.mjs`） | 94,596 B |
| wasm-gc（`lib.wasm`） | 25,341 B |

## 分かったこと

- **ブラウザーで使うだけなら、サーバーとの受け渡しの設計は要らない。** Workers 版のアダプター（wire 形式、線形メモリ）は、workerd が builtins を使えないことへの回避策だった。builtins が使えるブラウザーでは、`String` を引数と戻り値にした関数をそのまま export すればよい。
- **wasm-gc ビルドは js ビルドの 4 分の 1 ほど。** ただし builtins が要る。
- **同じ `render` をサーバーとブラウザーで共有するなら、今は js ビルドが確実。** Worker の中でも、ブラウザーでも同じファイルが動く。

## 確かめられなかったこと

- **Safari と Firefox。** 確かめたのは Chrome だけ。`js-string` builtins は新しい機能なので、対応していないブラウザーでは wasm-gc ビルドが動かない。そういうブラウザーで js ビルドに切り替える処理も書いていない。
- **workerd の互換性フラグ `wasm_esm_integration_builtins`**（[workerd PR #7685](https://github.com/cloudflare/workerd/pull/7685)、2026-10-12 マージ）。Worker の中の wasm-gc ビルドが動くようになるかもしれないが、今回の wrangler の workerd はマージより前のもので、試していない。
- **大きな文章での速さ。** 試したのは数行の Markdown だけ。

## 次の一歩

1. ブログの `render_blocks` と `render_inlines` を、`site` の外の公開パッケージに切り出す。そうすれば、ブラウザーのプレビューとブログのページが同じ HTML になる。
2. 編集ページを作るなら、ブログの `site.css` を当てて、見た目もブログに合わせる。
3. Worker の中で wasm-gc ビルドを使いたくなったら、`wasm_esm_integration_builtins` を試す。
