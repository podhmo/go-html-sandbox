# 調査メモ: MoonBit の Wasm を Cloudflare Workers で動かす

TODO.md の「Reimplement the blog in MoonBit」の前段の調査。ブログを移植する前に、MoonBit の Wasm バックエンド（`wasm-gc` と `wasm`）でビルドしたものを Workers から呼べるか、文字列をどう受け渡すかを、小さな spike で確かめた。
spike はリポジトリには入れておらず、要点のコードを末尾に載せた。
その後、spike を `moonbit/` に取り込み、`wrangler dev` で動くところまで進めた（「`moonbit/` への取り込み」の節）。

## 結論

- MoonBit を Workers に載せる公式の手順や定番のライブラリ（Go の [syumai/workers-go](https://github.com/syumai/workers-go) に当たるもの）は見つからなかった。JS の薄い Worker（`worker.mjs`）から Wasm を `import` して呼ぶ形を自分で書く。
- **`use-js-builtin-string` を使った wasm-gc は、そのままでは Workers で動かない。**
  - JS の文字列をそのまま受け渡すこの方式は、コンパイル時に `builtins: ["js-string"]` と `importedStringConstants` を渡すことが前提になっている。
  - しかし Workers では `import` した Wasm はコンパイル済みの `WebAssembly.Module` として渡され、コンパイルのオプションを指定できない。`wrangler dev` で試すと、import（`_` と `wasm:js-string`）が解決されないまま残っていた。
  - JS で polyfill しようにも、`wasm:js-string.fromCharCodeArray` は wasm-gc の配列を受け取り、JS からその中身は読めないので、書けない。
- **文字列を UTF-16 のコード単位ごとに受け渡す小さな ABI なら、`wasm-gc`（builtin string なし）でも `wasm`（線形メモリ）でも、`wrangler dev` 上で動いた。** wasm-gc が workerd で動くことも、これで確認できた。
- **本番の Workers にもデプロイでき、wasm-gc の Wasm がそのまま動いた**（「デプロイ」の節）。アップロードは 5.85 KiB（gzip 後 3.17 KiB）、起動時間は 2 ms。
- サイズは、ルーティングと HTML の組み立てだけの小さな関数で wasm-gc が 4.8 KB（gzip 後 2.4 KB）、wasm が 8.2 KB（同 4.2 KB）。Go 版（TinyGo で約 2 MiB）とは桁が違うが、ブログ全体を移植してから比べないと公平な比較にはならない。
- 移植は **wasm-gc（builtin string なし）+ コード単位の ABI** から始めるのがよい。サイズが小さく、GC を Wasm 側で持たずに済む。

## 環境

| | バージョン |
| --- | --- |
| moon | 0.1.20260920（`moon new` は新しい `moon.pkg` / `moon.mod` 形式を生成する） |
| moonc | v0.10.14（2026-09-18） |
| Node.js | 24.21.0（V8 での動作確認用） |
| wrangler | 4.147.0（`npx wrangler@4`）。spike はローカルの `wrangler dev` だけで確認した。`moonbit/` のものは後日デプロイした（「デプロイ」の節） |

## 調べたこと

### Workers 側

- Workers の [WebAssembly のドキュメント](https://developers.cloudflare.com/workers/runtime-apis/webassembly/) によると、`WebAssembly.instantiate()` はコンパイル済みの module しか受け付けない。バイト列から実行時にコンパイルすることはできず、ES module 形式の Worker から `.wasm` を `import` して使う。
- 対応する提案は「おおむね Chrome と同じ」とあるだけで、wasm-gc や js-string builtins への言及はなかった。実際に試して確かめた（後述）。
- Wasm の Worker は JS より大きくなりがちで起動に時間がかかるので、`wasm-opt` で小さくすることが勧められている。

### MoonBit 側

- MoonBit は `wasm`（線形メモリ）、`wasm-gc`、`js`、`native` を出力できる。
- wasm-gc で JS と文字列をやり取りする方法として、[JS String Builtins](https://moonbitlang.com/blog/js-string-builtins) がある。`moon.pkg` の link 設定で `"use-js-builtin-string": true` にすると、MoonBit の `String` が JS の文字列としてそのまま渡る。ホスト側は `builtins: ["js-string"]` と `importedStringConstants: "_"` を付けてコンパイルする。
- 新しい `moon.pkg` 形式では、link 設定は `options(link: { ... })` に書く（[package の設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)）。export する関数は `"exports"` に列挙する。

## 確認したこと

### 1. builtin string の wasm-gc は、オプション付きでコンパイルすれば動く

`render(path : String) -> String`（パスに応じた HTML を返すだけの関数）を `use-js-builtin-string` でビルドした。import は次のとおり。

- `_.<文字列リテラル>`：文字列定数ごとの global
- `wasm:js-string.length`、`charCodeAt`、`equals`、`fromCharCodeArray`

Node.js で `new WebAssembly.Module(bytes, { builtins: ["js-string"], importedStringConstants: "_" })` としてコンパイルすると、import なしでインスタンス化でき、`render("/")` が HTML を返した。

### 2. Workers ではコンパイルのオプションが効かない

同じ Wasm を `worker.mjs` から `import` し、import オブジェクトを空にして `WebAssembly.instantiate` すると、`wrangler dev` 上で次のエラーになった。

```
TypeError: WebAssembly.instantiate(): Import #0 "_": module is not an object or function
```

`WebAssembly.Module.imports()` にも `_` と `wasm:js-string` が残っており、workerd は builtins を有効にせずにコンパイルしていることが分かる。

### 3. JS の polyfill では補えない

コンパイルのオプションなしで、import を JS で与えてみた（Node.js で確認）。

| import | JS で与えられるか |
| --- | --- |
| `_.<リテラル>` | 与えられる。型が `(ref extern)` の immutable な global なので、`WebAssembly.Global` ではなく文字列そのものを渡す。`new Proxy({}, { get: (_, k) => k })` で全リテラルをまとめて渡せる |
| `length`、`charCodeAt`、`equals` | 与えられる（`s.length` など） |
| `fromCharCodeArray(array, start, end)` | **与えられない**。`array` は wasm-gc の `i16` 配列で、JS からは中身を読めない。`StringBuilder` の `to_string` などが使う |

wasm-gc の配列を読む関数を MoonBit 側から export すれば回避できるかもしれないが、コンパイラが生成する内部の型に依存することになるので試していない。

### 4. コード単位の ABI は両方のバックエンドで動く

文字列を JS と直接やり取りするのをやめ、UTF-16 のコード単位（`Int`）を 1 つずつ受け渡すことにした。

- リクエストのパスは、JS が export された `path_push(code)` を 1 文字ずつ呼んで渡す。
- `serve()` で HTML を組み立て、import した `host.put(code)` で 1 文字ずつ JS に返す。

こうすると import は `host.put` だけになり、`use-js-builtin-string` なしの wasm-gc でも線形メモリの wasm でも同じ JS から呼べる。`wrangler dev` で両方を試し、トップページと 404（パスの `<` `>` のエスケープを含む）が同じ HTML を返した。

## サイズ

`--release` でビルドしたもの。`wasm-opt` はかけていない。

| ビルド | サイズ | gzip -9 |
| --- | --- | --- |
| wasm-gc、`use-js-builtin-string`（`render` を export） | 4,249 B | — |
| wasm-gc、コード単位の ABI | 4,807 B | 2,450 B |
| wasm（線形メモリ）、コード単位の ABI | 8,239 B | 4,231 B |
| 参考: Go 版のブログ、TinyGo（[レポート](blog-tinygo-workers.md)） | 約 2 MiB | 約 760 KiB |
| 参考: Go 版のブログ、標準 Go | 約 8 MiB | — |

MoonBit の数字は「ルーティングと HTML の組み立てだけ」のもので、Markdown のパーサーも記事の埋め込みもない。Go 版との比較は、ブログを移植してから同じ条件で取り直す。

## `moonbit/` への取り込み

TODO.md の「Experiment with MoonBit's Wasm backends on Cloudflare Workers」の子タスクとして、spike の方式（wasm-gc、builtin string なし、コード単位の ABI）をリポジトリに入れた。

### 構成

| パス | 中身 |
| --- | --- |
| `moonbit/moon.mod` | モジュール `podhmo/blog`。`preferred_target = "wasm-gc"` |
| `moonbit/site/` | `render(path)`。トップページと、パスをエスケープした Not found ページを返す。`moon test` の対象 |
| `moonbit/worker/` | Wasm の入り口。`path_push` と `serve` を export し、`host.put` を import する |
| `moonbit/workers/` | Cloudflare Worker。`worker.mjs` と `wrangler.jsonc`（Worker 名は当面 `blog-moonbit`） |

- **`site` と `worker` を分けた理由**：`host.put` の import がテスト用のバイナリに入ると、`moon test` の実行時にその import を解決できない。`render` だけを持つ `site` をテストし、import は `worker` に閉じ込めた。
- **`workers/` という名前**：TODO では `moonbit/worker/` と書いていたが、`worker` は MoonBit のパッケージ名で使ったので、Go 版の `go/examples/blog/workers` にそろえた。
- ビルドした Wasm の export は `path_push` と `serve` だけ、import は `host.put` だけになっていることを確認した。

### spike からの変更

- **インスタンスは isolate ごとに 1 つ**：spike はリクエストのたびに `WebAssembly.instantiate` していたが、`worker.mjs` のトップレベルで一度だけ作るようにした。Workers の isolate は 1 スレッドで動くので、リクエスト間で状態が混ざることはない。`serve` はパスを読んだ直後に空にするので、`render` の途中で失敗しても次のリクエストに前のパスは残らない。
- **パスのデコード**：`decodeURIComponent` に失敗する壊れた `%` エスケープには、Wasm を呼ばずに 400 を返す。
- **ビルド**：`wrangler.jsonc` のビルドコマンドで `moon build --target wasm-gc --release` を実行し、Wasm を `workers/build/app.wasm` にコピーする（git では無視）。`build.watch_dir` に `../site` と `../worker` を指定し、`wrangler dev` 中にソースを書き換えると 1 秒ほどで再ビルドされて表示に反映されることを確認した。

### `wrangler dev` で確認したこと

| リクエスト | 結果 |
| --- | --- |
| `/` | 200、`text/html; charset=utf-8`、トップページ |
| `/a%3Cb%3E` | Not found ページに `/a&lt;b&gt;` と表示される。ステータスはまだ 200 |
| `/%E6%97%A5%E6%9C%AC` | `/日本` と表示される |
| `/%E0%A4%A` | 400 |

ステータスは常に 200 なので、404 を返すには ABI を広げる必要がある（次の一歩）。

なお、`wrangler dev` の既定のポート 8787 は、Go 版の Worker を `wrangler dev` で動かしていると使えない（`bind(): Address already in use` で workerd が起動に失敗する）。そのときは `--port` で別のポートを指定する。

### サイズ

`moonbit/` のビルド（`render` は spike より少し大きい）は 4,906 B、gzip -9 で 2,524 B。spike の 4,807 B とほぼ同じ。

## デプロイ

`moonbit/workers` で `npx wrangler deploy` を実行し、`blog-moonbit` という Worker として公開した。Go 版の `blog` とは別の Worker なので、そちらはそのまま残っている。この時点の `render` はトップページと Not found ページだけで、Go 版のブログの再現はまだしていない。目的は疎通の確認。

wrangler の出力（抜粋）:

```
[custom build] Running: cd .. && moon build --target wasm-gc --release && mkdir -p workers/build && cp _build/wasm-gc/release/build/worker/worker.wasm workers/build/app.wasm
Total Upload: 5.85 KiB / gzip: 3.17 KiB
Worker Startup Time: 2 ms
Uploaded blog-moonbit (1.06 sec)
Deployed blog-moonbit triggers (0.84 sec)
  https://blog-moonbit.ababjam61.workers.dev
```

- アップロード時に wasm-gc が拒否されることはなく、追加の設定（互換性フラグなど）も要らなかった。
- アップロードの 5.85 KiB は、Wasm（4,906 B）と `worker.mjs` を合わせたもの。

公開 URL に対して確認したこと:

| リクエスト | 結果 |
| --- | --- |
| `/` | 200、`content-type: text/html; charset=utf-8`、トップページ |
| `/a%3Cb%3E` | Not found ページに `/a&lt;b&gt;` と表示される（ステータスはまだ 200） |
| `/%E6%97%A5%E6%9C%AC` | `/日本` と表示される |
| `/%E0%A4%A` | 400 |

`wrangler dev` と同じ結果になった。手元（日本）から `curl` で `/` を 5 回取ったときの所要時間は 0.38〜0.44 秒だったが、TLS の接続を含む往復の時間で、Worker の処理時間ではない。

## 未確認のこと

- **性能**：コード単位ごとに Wasm と JS を行き来するコスト。数十 KB のページなら問題ないと思うが測っていない。重ければ、線形メモリの wasm で UTF-8 のバイト列をメモリ越しにまとめて渡す ABI に切り替える。
- **`wasm-opt`** をかけたときのサイズ（手元に入っていなかった）。
- **ステータスコードとヘッダー**：spike は常に 200 の HTML を返す。404 や `text/markdown`、`Cache-Control` を返すには、ABI に「ステータス」と「ヘッダー」を足す必要がある。
- **記事の埋め込み**：MoonBit に `go:embed` に当たる仕組みがあるかは調べていない。なければ、Markdown を MoonBit のソースに変換するコード生成を挟む。

## 次の一歩

1. （済み）トップレベルに `moonbit/` を作り、spike の ABI と `worker.mjs` を置く。「`moonbit/` への取り込み」の節を参照。
2. ステータスとヘッダーを返せるように ABI を広げ、存在しないパスに 404 を返す。
3. `moonbit/Makefile` に `build`、`test`、`dev`、`deploy` を用意する。
4. （済み）本番に `blog-moonbit` としてデプロイし、wasm-gc が受け付けられるかを確かめて、アップロードサイズを追記する。「デプロイ」の節を参照。
5. `wasm-opt -Oz` をかけたサイズと、コード単位の受け渡しにかかる時間を測る。
6. `pkg/el`（HTML ビルダー）と `pkg/tinymarkdown`（Markdown パーサー）を移植し、記事 1 本を表示するところまで作る。Go 版とサイズを比べて、このレポートに追記する。

## spike のコード

記録として残す。今のコードは `moonbit/` にある（[`worker/worker.mbt`](../../../moonbit/worker/worker.mbt)、[`workers/worker.mjs`](../../../moonbit/workers/worker.mjs)）。

`moon new mbspike` で作ったプロジェクトのルートパッケージ。

`moon.pkg`:

```
options(
  link: {
    "wasm-gc": { "exports": [ "path_push", "serve" ] },
    "wasm": { "exports": [ "path_push", "serve" ] },
  },
)
```

`abi.mbt`（`render` はパスに応じた HTML を `String` で返す関数）:

```moonbit
///|
/// put sends one UTF-16 code unit of the response body to the host.
fn put(code : Int) = "host" "put"

///|
let input : StringBuilder = StringBuilder()

///|
/// path_push appends one UTF-16 code unit of the request path.
pub fn path_push(code : Int) -> Unit {
  input.write_char(code.unsafe_to_char())
}

///|
/// serve renders the page for the pushed path, sends it through put, and
/// clears the path.
pub fn serve() -> Unit {
  let path = input.to_string()
  input.reset()
  let html = render(path)
  for i in 0..<html.length() {
    put(html.code_unit_at(i).to_int())
  }
}
```

`worker.mjs`（`wrangler.jsonc` は `"main": "./worker.mjs"` だけ。ビルドした Wasm を隣に置く）:

```js
import gc from "./app-gc.wasm";
import linear from "./app-linear.wasm";

// render runs one of the MoonBit builds: the path goes in and the HTML
// comes out one UTF-16 code unit at a time, through path_push and host.put.
async function render(mod, path) {
  let out = [];
  const inst = await WebAssembly.instantiate(mod, {
    host: { put: (c) => out.push(c) },
  });
  for (let i = 0; i < path.length; i++) inst.exports.path_push(path.charCodeAt(i));
  inst.exports.serve();
  let s = "";
  for (let i = 0; i < out.length; i += 8192) s += String.fromCharCode(...out.slice(i, i + 8192));
  return s;
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const mod = url.searchParams.get("backend") === "wasm" ? linear : gc;
    return new Response(await render(mod, decodeURIComponent(url.pathname)), {
      headers: { "content-type": "text/html; charset=utf-8" },
    });
  },
};
```
