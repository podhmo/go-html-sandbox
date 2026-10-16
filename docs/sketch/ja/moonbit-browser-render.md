# 探索メモ: MoonBit の tinymarkdown と el を wasm-gc でブラウザーから呼ぶ

記事の編集ページのようなもの（今はない）で、入力中の Markdown を MoonBit の `tinymarkdown` で読み、`el` で HTML にしてその場でプレビューできるかを確かめた記録（2026-10-16）。
これまでの MoonBit 版は、Workers の上で Wasm が要求を受けて応答を返す形（[アダプターの探索メモ](moonbit-workers-http.md)）だけだった。サーバーを通さず、ブラウザーの JS から wasm-gc の Wasm の関数を直接呼べるかを見た。
spike は `moonbit/experiments/browser-render` に置いた。

## 結論

- **ブラウザーから直接呼べる。** `tinymarkdown`、`el`、`picoel` はホストに依存しない純粋な MoonBit なので、`render(md : String) -> String` を 1 つ export するパッケージを wasm-gc でビルドすれば、ページの JS から普通の関数として呼べる。Node 24.21.0 と Chrome 155（headless）で確かめた。
- **文字列はそのまま渡せる。** `"use-js-builtin-string": true` でビルドし、`WebAssembly.instantiateStreaming(fetch(...), {}, { builtins: ["js-string"], importedStringConstants: "_" })` でコンパイルすると、import が空になる。JS の文字列を引数に渡し、戻り値も JS の文字列で受け取れる。Workers 版のような線形メモリを通した受け渡し（wire 形式）は要らない。
- **Workers から配るだけなら、Worker 側には何も要らない。** Static Assets で `index.html` と `lib.wasm` を配れば、描画はブラウザーで行われる。`wrangler dev --assets .` で確かめた。
- **同じ Wasm を Worker の中で呼ぶことは、今はできない。** workerd が import した Wasm を builtins なしでコンパイルするので、インスタンスを作れない（[調査メモ](moonbit-workers-wasm.md)と同じ問題）。

## spike の形

`moonbit/experiments/browser-render` は、ほかの experiments と同じく独立したモジュールで、`moon.work` でブログのモジュール（`../..`）を読む。

- `lib/lib.mbt`: `render`。`@tinymarkdown.parse` で読み、`picoel` で要素を組み、`@el.render_html` で文字列にする。
- `lib/moon.pkg`: link 設定。wasm-gc の部分は次のとおり。

  ```moonbit
  options(
    link: {
      "wasm-gc": { "exports": [ "render" ], "use-js-builtin-string": true },
    },
  )
  ```

- `index.html`: 左の textarea に入力するたびに `render` を呼び、右に `innerHTML` で表示する。1 回の描画にかかった時間を出す。
- `try.mjs`: Node で `render` を呼ぶ。
- `Makefile`: `build`、`try`、`serve`（`python3 -m http.server`）、`dev`（`wrangler dev --assets .`）、`screenshot`（headless Chrome）。

比べるために js ターゲットのビルドも置いてあり、`index.html` で切り替えられる。

`render` はブログの `render_blocks` と `render_inlines`（`moonbit/examples/blog/site/views.mbt`）を小さく写したもの。ブログのものは非公開なので使えなかった。見出しは h2 と h3 だけで、リンクの URL は検査しない。本文の文字はすべて `@picoel.text` を通るので、Markdown に書いた `<b>` はエスケープされ、出力を `innerHTML` に入れてよい。

## 試したこと

### 1. Node

`make try` の出力。

```
imports: []
wasm: <article><section><h2>見出し</h2><p>本文 <code>code</code> と <a href="https://example.com">リンク</a> &lt;b&gt;esc&lt;/b&gt;</p><ul><li>a</li><li>b</li></ul></section></article>
```

builtins を有効にしてコンパイルすると `WebAssembly.Module.imports` が空になるので、import オブジェクトを用意しなくてよい。

### 2. ブラウザー（Chrome 155、headless）

`make serve` で配ったページを `--dump-dom` と `--screenshot` で見た。見出し、コード、リンク、リスト、表が描画された。1 回の描画（`render` と `innerHTML` の代入）は 1.7〜5.5 ms だった。計ったのは数回だけで、ベンチマークではない。

### 3. Workers の Static Assets で配る

`make dev`（`wrangler dev --assets . --compatibility-date 2026-10-01`）で同じページを配り、Chrome で開いた。`.wasm` は `Content-Type: application/wasm` で返り、そのまま描画された。Worker の JS は書いていない。

`--assets .` はディレクトリをまるごとアセットにするので、ローカルで確かめる用。そのまま deploy すると `_build` なども上がる。

### 4. Worker の中で呼ぶ

`/tmp` に置いた使い捨ての Worker で、同じ `lib.wasm` を `import` して `render` を呼んだ（wrangler 4 の `wrangler dev`）。

`new WebAssembly.Instance(wasm, {})` が `TypeError: WebAssembly.Instance(): Import #0 "_": module is not an object or function` で失敗した。`WebAssembly.Module.imports` には、文字列リテラルの `_.<リテラル>`（global）と `wasm:js-string` の 6 関数（`length`、`charCodeAt`、`equals`、`concat`、`fromCodePoint`、`fromCharCodeArray`）が残っていた。

## サイズ

`lib.wasm` は 25,341 B（`moon build --release` の出力そのまま、wasm-opt なし）。

## 分かったこと

- **ブラウザーで使うだけなら、受け渡しの設計は要らない。** Workers 版のアダプター（wire 形式、線形メモリ）は、workerd が builtins を使えないことへの回避策だった。builtins が使えるブラウザーでは、`String` を引数と戻り値にした関数をそのまま export すればよい。
- **ブラウザー向けとブログの Worker 向けで、同じ Wasm は使えない。** ブログの Worker は wire 形式の `serve` を export した Wasm で、ブラウザー向けは builtins を前提にした Wasm になる。共有できるのは MoonBit のパッケージで、ビルドは別々になる。

## 確かめられなかったこと

- **Safari と Firefox。** 確かめたのは Chrome だけ。`js-string` builtins は新しい機能なので、対応していないブラウザーでは動かない。
- **workerd の互換性フラグ `wasm_esm_integration_builtins`**（[workerd PR #7685](https://github.com/cloudflare/workerd/pull/7685)、2026-10-12 マージ）。Worker の中でも同じ Wasm が動くようになるかもしれないが、今回の wrangler の workerd はマージより前のもので、試していない。
- **大きな文章での速さ。** 試したのは数行の Markdown だけ。

## 次の一歩

1. ブログの `render_blocks` と `render_inlines` を、`site` の外の公開パッケージに切り出す。そうすれば、ブラウザーのプレビューとブログのページが同じ HTML になる。
2. 編集ページを作るなら、ブログの `site.css` を当てて、見た目もブログに合わせる。
3. Worker の中でも同じ Wasm を使いたくなったら、`wasm_esm_integration_builtins` を試す。
