# 探索メモ: wasm-gc の Wasm だけで、ブラウザーの tinymarkdown と el を動かす

記事の編集ページのようなもの（今はない）で、入力中の Markdown を MoonBit の `tinymarkdown` で読み、`el` で HTML にしてその場でプレビューする。これを **wasm-gc の Wasm だけで**できるかを確かめた記録（2026-10-16）。
spike は `moonbit/experiments/browser-render` に置いた。

## 何を確かめたか

MoonBit は JS にもビルドできるので、js ビルドならブラウザーでも Worker でも動くのは当たり前。それでもこのブログは、Wasm で動かすこと自体を目的にしている（[Go から MoonBit へ](../../../posts/2026-10-18-moonbit.md)の「ロマン」）。
なので、ここで確かめたのは **MoonBit が生成する JS を使わず、wasm-gc の `.wasm` 1 つで足りるか**だ。js ビルドはベースラインとして置いただけで、結論には使っていない。

問いと答えは次のとおり。どの問いも、確かめたのは wasm-gc ビルド（`build/lib.wasm`）。

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. MoonBit が生成する JS なしに、`.wasm` だけでブラウザーで動くか | **動く** | Chrome 155 で `index.html` を開き、プレビューが描画された。ページが取ったのは `/` と `/build/lib.wasm` だけ（サーバーのログ） |
| 2. 文字列の受け渡しに、Workers 版のような ABI（wire 形式、線形メモリ）が要るか | **要らない** | `js-string` builtins を有効にしてコンパイルすると、import が 69 個から 0 個になる。`render` は JS の文字列を受け取り、JS の文字列を返す（Node） |
| 3. Workers から配って動くか | **動く** | `wrangler dev --assets .` の Static Assets で配り、Chrome で描画された。Worker のコードは書いていない |
| 4. 同じ `.wasm` を Worker の中でも呼べるか | **呼べない** | Worker で `import` すると、69 個の import が残り、インスタンスを作るところで `TypeError` になる。同じ Worker でベースラインは動くので、Worker の環境の問題ではない |

## 結論

- **ブラウザーでは、wasm-gc の `.wasm` だけで足りる。** ページに要る JS は、Wasm をコンパイルし、`render` を呼び、戻り値を `innerHTML` に入れる十数行だけ。MoonBit が生成した JS は 1 行も読み込んでいない。
- **文字列はそのまま渡せる。** `"use-js-builtin-string": true` でビルドし、`{ builtins: ["js-string"], importedStringConstants: "_" }` を付けてコンパイルすれば、`String` を引数と戻り値にした関数をそのまま export すればよい。Workers 版のアダプター（wire 形式）は、workerd が builtins を使えないことへの回避策で、ブラウザーでは要らない。
- **Worker の中では、同じ `.wasm` はまだ動かない。** workerd は `import` した Wasm を builtins なしでコンパイルするので、文字列の import が解決されない（[調査メモ](moonbit-workers-wasm.md)と同じ問題）。ブラウザー向けの `.wasm` とブログの Worker の `.wasm`（wire 形式の `serve`）は別のビルドになり、共有できるのは MoonBit のパッケージまで。

## spike の形

`moonbit/experiments/browser-render` は、ほかの experiments と同じく独立したモジュールで、`moon.work` でブログのモジュール（`../..`）を読む。

- `lib/lib.mbt`: `render(md : String) -> String`。`@tinymarkdown.parse` で読み、`picoel` で要素を組み、`@el.render_html` で文字列にする。
- `lib/moon.pkg`: link 設定。wasm-gc は builtins を使う。js はベースライン。

  ```moonbit
  options(
    link: {
      "js": { "exports": [ "render" ], "format": "esm" },
      "wasm-gc": { "exports": [ "render" ], "use-js-builtin-string": true },
    },
  )
  ```

- `index.html`: 編集ページ。左の textarea に入力するたびに `lib.wasm` の `render` を呼び、右に表示する。読み込むのは `lib.wasm` だけ。
- `baseline.html`: `index.html` の `lib.wasm` を js ビルド（`lib.mjs`）に替えたもの。
- `try.mjs`: Node で `lib.wasm` を builtins なしとありでコンパイルして import を数え、`render` を呼ぶ。最後にベースラインと出力を比べる。
- `worker.mjs`、`wrangler-worker.json`: `lib.wasm` を Worker で `import` して呼ぶ（問い 4）。
- `Makefile`: `build`、`try`、`serve`、`dev`（Static Assets）、`dev-worker`、`screenshot`。

`render` はブログの `render_blocks` と `render_inlines`（`moonbit/examples/blog/site/views.mbt`）を小さく写したもの。見出しは h2 と h3 だけで、リンクの URL は検査しない。本文の文字はすべて `@picoel.text` を通るので、Markdown に書いた `<b>` はエスケープされ、出力を `innerHTML` に入れてよい。

## 問いごとの結果

### 1. `.wasm` だけでブラウザーで動くか

`make serve` で配った `index.html` を、headless の Chrome 155 で `--dump-dom` と `--screenshot` を付けて開いた。見出し、コード、リンク、リスト、表が描画された。

ページのスクリプトは次の部分がすべて（`update` は入力のたびに呼ぶ）。

```js
const { instance } = await WebAssembly.instantiateStreaming(fetch("./build/lib.wasm"), {},
  { builtins: ["js-string"], importedStringConstants: "_" });
const { render } = instance.exports;
// ...
document.getElementById("out").innerHTML = render(src.value);
```

`python3 -m http.server` のログに残ったリクエストは、次の 3 つだけ。

```
"GET / HTTP/1.1" 200
"GET /build/lib.wasm HTTP/1.1" 200
"GET /favicon.ico HTTP/1.1" 404
```

1 回の描画（`render` と `innerHTML` の代入）は 1.7〜6.2 ms だった。計ったのは数回だけで、ベンチマークではない。

### 2. 文字列の受け渡しに ABI が要るか

`make try` の出力。

```
without builtins: 69 imports (63 from "_", 6 from "wasm:js-string")
with builtins: 0 imports
render: string: <article><section><h2>見出し</h2><p>本文 <code>code</code> と <a href="https://example.com">リンク</a> &lt;b&gt;esc&lt;/b&gt;</p><ul><li>a</li><li>b</li></ul></section></article>
baseline (js) gives the same HTML: true
```

builtins なしでコンパイルすると、文字列リテラル（`_` の global、63 個）と `wasm:js-string` の関数（6 個）が import として残る。builtins を有効にすると、これらはエンジンが埋めるので import は 0 個になり、import オブジェクトなしでインスタンスを作れる。`render` の戻り値は `typeof` が `string` の、JS の文字列そのもの。

### 3. Workers から配って動くか

`make dev`（`wrangler dev --assets . --compatibility-date 2026-10-01`、wrangler 4.148.0）で同じページを配り、Chrome で開いた。`.wasm` は `Content-Type: application/wasm` で返り、問い 1 と同じく描画された。Worker は Static Assets を返すだけで、Worker の JS は書いていない。

`--assets .` はディレクトリをまるごとアセットにするので、ローカルで確かめる用。そのまま deploy すると `_build` なども上がる。

### 4. 同じ `.wasm` を Worker の中でも呼べるか

`make dev-worker`（wrangler 4.148.0）の応答。

```json
{"imports":69,"error":"TypeError: WebAssembly.Instance(): Import #0 \"_\": module is not an object or function","baseline":"<article><section><h2>見出し</h2></section></article>"}
```

workerd は `import` した Wasm を builtins なしでコンパイルするので、import は Node で builtins なしにしたときと同じ 69 個のまま残り、インスタンスを作れない。同じ Worker の中でベースラインの js ビルドは HTML を返したので、失敗の原因は Worker の環境ではなく、builtins がないこと。

## サイズ

`moon build --release` の出力そのまま（wasm-opt なし）。

| ビルド | 大きさ |
| --- | --- |
| wasm-gc（`lib.wasm`） | 25,342 B |
| js（`lib.mjs`、ベースライン） | 94,610 B |

## 確かめられなかったこと

- **Safari と Firefox。** 確かめたのは Chrome だけ。`js-string` builtins に対応していないブラウザーでは、問い 1 と 2 の答えが変わる。
- **入力しながらの更新。** headless の Chrome で見たのは、ページを開いたときの最初の描画だけ。入力のたびに呼ぶ `update` は同じ関数だが、キー入力を送って確かめてはいない。
- **workerd の互換性フラグ `wasm_esm_integration_builtins`**（[workerd PR #7685](https://github.com/cloudflare/workerd/pull/7685)、2026-10-12 マージ）。問い 4 の答えが変わるかもしれないが、今回の wrangler の workerd はマージより前のもので、試していない。
- **大きな文章での速さ。** 試したのは数行の Markdown だけ。

## 次の一歩

1. 編集ページを作るなら、ブログの `site.css` を当てて、見た目もブログに合わせる。
2. Worker の中でも同じ `.wasm` を使いたくなったら、`wasm_esm_integration_builtins` を試す。
