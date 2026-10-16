# 探索メモ: ブラウザーの中で、2 つの wasm-gc の Wasm をつなぐ

[wasm-gc の Wasm だけでブラウザーの tinymarkdown と el を動かす探索](moonbit-browser-render.md)の続き（2026-10-16）。
今度は処理を 2 つの Wasm に分け、ブラウザーの中でつないだ。1 つは Markdown を読んで JSON にする `parser.wasm`、もう 1 つは JSON を HTML にする `html.wasm`。
spike は `moonbit/experiments/wasm-pair` に置いた。

## 何を確かめたか

つなぎ方には、同じスレッドで関数として呼び合う形（同期）と、Wasm ごとに Web Worker を分けてメッセージで通信する形（非同期）がある。どちらも MoonBit が生成する JS は使わず、wasm-gc の `.wasm` だけで組んだ。

| 問い | 答え | 確かめ方 |
| --- | --- | --- |
| 1. JS が仲介して、片方の出力をもう片方に渡せるか | **渡せる** | `html.render(parser.parse(md))`。Node と Chrome 155 |
| 2. JS を挟まず、Wasm から別の Wasm の関数を直接呼べるか | **呼べる** | `linked.wasm` が import として宣言した `html.render` に、`html.wasm` の export をそのまま渡した。1 と同じ HTML が返った（Node と Chrome） |
| 3. Wasm ごとに Worker を分け、メッセージでつなげるか | **つなげる** | parser の Worker から html の Worker へ、MessageChannel で直接渡した。ページは Markdown を送り、HTML を受け取るだけ（Chrome） |
| 4. 重い処理でも、3 ならページが固まらないか | **固まらない** | 約 210 万文字の Markdown で、1 と 2 はページを約 360 ms 止めた。3 で止まったのは 11 ms で、10 ms のタイマーの間隔と同じ程度（Chrome） |

## 結論

- **軽い処理は同期でよい。** 1 と 2 は普通の関数呼び出しで、エディターに打つ程度の文章なら数 ms で終わる。2 の形にすると、JS は 2 つの Wasm を最初につなぐだけで、その後は呼び出しの間に入らない。
- **重い処理は Worker に分ければ、ページが固まらない。** 3 は全体の時間が少し長くなる（文字列のコピーとメッセージの往復の分）。その代わり、処理している間もページのスレッドは空いている。
- **Wasm 同士の境界で渡すのは文字列（ここでは JSON）。** MoonBit の値（`Document` など）は、別々にビルドしたモジュールの間では共有できない。postMessage でも wasm-gc のオブジェクトは送れない。builtins を使えば、文字列は JS の文字列のまま行き来する。
- **Wasm 自身は postMessage を呼べない。** Worker の中の Wasm は、呼ばれて返すだけの関数。メッセージを受けて export を呼び、結果を送り返すのは、Worker ごとの十数行の JS。

## spike の形

`moonbit/experiments/wasm-pair` は、ほかの experiments と同じく独立したモジュールで、`moon.work` でブログのモジュール（`../..`）を読む。3 つのパッケージを、どれも `"use-js-builtin-string": true` の wasm-gc でビルドする。

| パッケージ | export | import | 大きさ |
| --- | --- | --- | --- |
| `parser` | `parse(md : String) -> String`（ブロックとインラインの木を JSON にする） | なし | 34,498 B |
| `html` | `render(json : String) -> String`（JSON を picoel と el で HTML にする） | なし | 62,522 B |
| `linked` | `preview(md : String) -> String`（`parser` を MoonBit のパッケージとして含み、`html` の `render` を呼ぶ） | `html.render` | 34,529 B |

`html` の大きさのほとんどは、`@json.parse` の分。`html` は Markdown を知らず、`tinymarkdown` も含まない。

`linked` の import は、MoonBit の FFI で次のように書いた。引数も戻り値も `String` のままでよい。

```moonbit
fn render(json : String) -> String = "html" "render"
```

ほかのファイル:

- `index.html`: 編集ページ。つなぎ方を 3 つから選べる。`/?check` で開くと、問い 4 の計測をする。
- `wasm.mjs`: builtins を付けて `.wasm` を読み込む関数。ページと Worker で共有する。
- `parser-worker.mjs`、`html-worker.mjs`: Worker の殻。
- `try.mjs`: Node で 1 と 2 を確かめる（`make try`）。
- `check.mjs`: headless の Chrome を DevTools protocol で動かし、`/?check` の結果を読む（`make check-browser`）。

## 問いごとの結果

### 1. JS が仲介する

```js
const parser = await load("parser");
const html = await load("html");
html.render(parser.parse(md));
```

`make try` で、`parse` が返した JSON と、`render` がそれから作った HTML を見た。入れ子のリスト、コード、リンクも、エスケープも、[前の探索](moonbit-browser-render.md)の `render` と同じ形になった。

### 2. Wasm から別の Wasm の関数を直接呼ぶ

```js
const linked = await load("linked", { html: { render: html.render } });
linked.preview(md);
```

`WebAssembly.Module.imports` で見た `linked.wasm` の import は、`[{"module":"html","name":"render","kind":"function"}]` の 1 つだけ。そこに `html.wasm` の export（Wasm の関数）を JS の関数で包まずに渡した。`linked.preview(md)` は、1 の `html.render(parser.parse(md))` と同じ文字列を返した（Node と Chrome）。

エンジンがこの呼び出しを Wasm から Wasm への直接の呼び出しにしているか（JS を経由する層があるか）は、確かめていない。

### 3. Worker を分けて、メッセージでつなぐ

ページは Worker を 2 つ作り、MessageChannel の両端を 1 つずつ渡す。

```
page --(md)--> parser Worker --(json, MessagePort)--> html Worker --(html)--> page
```

- `parser-worker.mjs`: ページから `{ id, md }` を受け、`parse` した JSON を `{ id, json }` としてポートに送る。
- `html-worker.mjs`: ポートから `{ id, json }` を受け、`render` した HTML を `{ id, html }` としてページに送る。
- ページは `id` ごとに Promise を待つ。入力が速いときは、最後の入力の結果だけを表示する。

JSON はページを通らず、Worker の間で直接渡る。「ブラウザーの中で parser と html のサービスが動いている」形になる。

**Worker を書くときの落とし穴**: 最初は Worker の中で `const { parse } = await load("parser")` としてから `onmessage` を設定していた。これだと、ページが先に送ったポートのメッセージが失われる。`html` が `undefined` のまま、`TypeError: Cannot read properties of undefined (reading 'postMessage')` になった。トップレベルの `await` が終わるまでハンドラーがないので、その間に届いたメッセージは誰にも受け取られない。ハンドラーを先に設定し、その中で読み込みの Promise を待つようにして直した。

### 4. 重い処理でページが固まるか

`/?check` は、サンプルの Markdown を 20,000 回つないだもの（2,100,000 UTF-16 コード単位）を、3 つの形に 1 回ずつ通す。測るのは次の 2 つ。

- 結果が返るまでの時間
- その間、10 ms ごとのタイマーの間隔がいちばん開いたところ。これがページのスレッドが止まっていた時間になる。

先に 1 回ずつ通して温めてある。`make check-browser` を 4 回動かした結果は次のとおり。

| 形 | 返るまで | ページが止まった時間 | 1 と同じ HTML |
| --- | --- | --- | --- |
| 1. JS が仲介（同期） | 355〜359 ms | 358〜364 ms | — |
| 2. 直接呼ぶ（同期） | 356〜371 ms | 356〜372 ms | true |
| 3. Worker 2 つ（非同期） | 390〜416 ms | 11 ms | true |

1 と 2 は、処理している間ずっとページが止まる。この間は入力も描画もできない。3 は全体で 30〜60 ms 長いが、ページのスレッドはタイマーの間隔どおりに動き続けた。`--virtual-time-budget` を付けた headless の Chrome は仮想の時間で動き、タイマーの間隔が実際とずれるので、計測には使わなかった。

1 と 2 の差は、測った範囲では見分けられなかった。2 で JS を挟まなくなっても、呼ぶのは文書ごとに 1 回なので、時間のほとんどはパースと HTML を作ることにかかる。

## 確かめられなかったこと

- **Safari と Firefox。** 確かめたのは Chrome だけ。
- **入力しながらの更新。** 計測は `/?check` の一括の処理だけで、キー入力を送って確かめてはいない。
- **2 の呼び出しが、エンジンの中でどう扱われるか**（問い 2 の節）。
- **Worker を増やしたときの形。** 3 は Worker 1 つにつき Wasm 1 つ。同じ Wasm を複数の Worker で並べて動かしたり、コンパイル済みの `WebAssembly.Module` を postMessage で配ったりはしていない。
- **SharedArrayBuffer でメモリを共有する形。** MoonBit の wasm-gc はデータを GC ヒープに置くので、試していない。

## 次の一歩

1. 編集ページを作るなら、普段は 1 か 2 で描画する。長い文書だけ Worker に回すと、短い文書での往復の遅れもなくなる。
2. 同じ Wasm を複数の Worker で動かすときは、コンパイル済みの `WebAssembly.Module` を postMessage で配る形を試す。
