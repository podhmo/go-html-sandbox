---
title: 同じ wasm をブラウザーと Worker で動かしたい
description: MoonBit の tinymarkdown と el を wasm-gc のままブラウザーで動かすことはできた。理想ではこのブログの Worker と同じ wasm でつながるはずなのに、今はつながらない。その理由と、つながりそうな道筋。
---
記事を書く画面があったとして、打った Markdown をその場でプレビューしたい。
このブログが記事を描画しているのは、MoonBit の `tinymarkdown` と `el` だ。
同じ処理をブラウザーでも動かせば、プレビューは記事のページとずれない。

[前の記事](./2026-10-18-moonbit.md)に書いたとおり、このブログを wasm で動かしているのはロマンだ。
MoonBit は JS にもビルドできるので、JS にすればブラウザーでも Worker でも動くのは当たり前。
だからここでも JS ではなく、wasm-gc の `.wasm` だけでやる。

## 理想の形

```moonbit
pub fn render(md : String) -> String
```

この関数を 1 つ export した `.wasm` を作る。
Worker はこれを呼んで記事のページを返し、ブラウザーは同じファイルを読み込んでプレビューを描く。
処理を `parser.wasm`（Markdown から JSON）と `html.wasm`（JSON から HTML）に分けて、組み合わせてもいい。

## ブラウザーでは、つながった

wasm-gc の MoonBit は、`use-js-builtin-string` でビルドすると、文字列を JS の文字列のまま扱う。
ブラウザーで `builtins: ["js-string"]` を付けてコンパイルすると、wasm の import が 69 個から 0 個になった。
MoonBit が生成した JS を 1 行も読み込まずに、`render(src.value)` の戻り値をそのまま `innerHTML` に入れられる。

2 つの wasm をつなぐのも、思ったより素直だった。

- **同じスレッドで呼び合う。** `linked.wasm` が import として宣言した `render` に、`html.wasm` の export をそのまま渡すと、wasm から別の wasm の関数を呼べた。MoonBit の側は `fn render(json : String) -> String = "html" "render"` と書くだけ。
- **Worker に分ける。** parser と html をそれぞれ Web Worker に置き、MessageChannel で Worker 同士をつないだ。ブラウザーの中で 2 つの小さなサービスが動いている形になる。

約 210 万文字の Markdown を通すと、同じスレッドの形は処理のあいだ（約 360 ms）ページを止めた。
Worker の形で止まったのは 11 ms だけだった。
打ちながらのプレビューなら同期で数 ms なので、重いときだけ Worker に回せばいい。

## Worker では、つながらない

同じ `.wasm` を Worker で `import` すると、インスタンスを作るところで失敗する。

```
TypeError: WebAssembly.Instance(): Import #0 "_": module is not an object or function
```

workerd は `import` した wasm を builtins なしでコンパイルする。
すると、ブラウザーでは消えた 69 個の import が、文字列リテラルと `wasm:js-string` の関数として残る。
コンパイルのオプションを渡す口もない。

このブログの Worker が、[線形メモリで文字列を受け渡す](./2026-10-19-moonbit-memory.md)小さな ABI を持っているのは、これを避けるためだった。
その結果、ブログの Worker の wasm（ABI の `serve` を export する）と、ブラウザーの wasm（文字列をそのまま受け渡す）は、別のビルドになる。
同じ MoonBit のコードから作っても、同じファイルにはならない。

ブラウザー用の `.wasm` と編集ページを、ブログの Worker から配ることはできる。
描画はブラウザーでするので、Worker はファイルを返すだけでいい。
ただしそれは「同じ wasm でつながった」のではなく、別々の wasm が並んでいるだけだ。

## つながりそうな道

workerd に、互換性フラグ `wasm_esm_integration_builtins` が入った（[PR #7685](https://github.com/cloudflare/workerd/pull/7685)、2026-10-12 マージ）。
`import` した wasm を、ブラウザーと同じ `js-string` builtins を付けてコンパイルするフラグだ。
これが効けば、ブログの Worker でも文字列をそのまま受け渡せて、ABI はいらなくなる。
そうなれば、Worker とブラウザーで同じ `.wasm` を使える。

ただ、このフラグはまだ試せていない。
フラグが入った workerd は v1.20261013.1 からで、この記事を書いた時点の wrangler（4.151.1）に入っている workerd はそれより前のものだった。
本番の Workers で使えるかも、まだ確かめていない。

理想ではつながるはずの形が、今は 1 つのコンパイルのオプションだけで止まっている。
フラグが使えるようになったら、続きを書く。

詳しくは探索メモにまとめてある。

- [wasm-gc の Wasm だけで、ブラウザーの tinymarkdown と el を動かす](../docs/sketch/ja/moonbit-browser-render.md)
- [ブラウザーの中で、2 つの wasm-gc の Wasm をつなぐ](../docs/sketch/ja/moonbit-wasm-pair.md)
