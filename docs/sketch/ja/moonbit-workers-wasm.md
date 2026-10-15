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
- **コード単位の ABI は、時間の約 8 割を JS との受け渡しに使うが、51 KB のページでも 1 リクエスト 0.4 ms 前後で済む**（「計測」の節）。今のところ、受け渡し方を変える必要はない。
- `wasm-opt -Oz` をかけると 5,279 B が 4,021 B になる（gzip 後は 2,744 B が 2,110 B）。差は 600 B ほどなので、ビルドには入れていない。
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

この時点ではステータスは常に 200 だった。その後 ABI を広げて 404 を返すようにした（「ステータスとヘッダー」の節）。

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

デプロイしたのは、次の「ステータスとヘッダー」より前の版なので、公開中の Worker は存在しないパスにも 200 を返す。

## ステータスとヘッダー

`site.render` が `Response`（`status`、`headers`、`body`）を返すようにし、ABI を次のように広げた。import は 4 つになった。

| import | 役割 |
| --- | --- |
| `host.put(code)` | UTF-16 のコード単位を 1 つ、JS 側のバッファに足す |
| `host.status(code)` | ステータスコードを設定する |
| `host.header_name()` | バッファの中身を取り出し、次のヘッダーの名前にする |
| `host.header_value()` | バッファの中身を取り出し、直前の名前のヘッダーの値にする |

`serve` は、ステータス、ヘッダー（名前と値の組ごと）、本文の順に送る。`serve` が返った時点でバッファに残っているものが本文になる。文字列を渡す手段は `put` だけのままなので、ヘッダーの数や種類が増えても import は増えない。

`wrangler dev` で、`/` は 200、存在しないパスは 404（どちらも `Content-Type: text/html; charset=utf-8`）、壊れた `%` エスケープは 400 を返すことを確認した。`moon test` でも、`render` が選ぶステータスと `content-type` を確かめている。Wasm は 5,279 B になった。

## Makefile

`moonbit/Makefile` に `build`、`test`、`check`（`moon fmt --check`、`moon check`、`moon test`）、`dev`、`deploy`、`clean` を用意した。`go/Makefile` と同じく、`moonbit/` の中で実行する（ルートの Makefile はない）。`make dev PORT=8798` のようにポートを変えられるので、Go 版の Worker が 8787 番を使っていても動かせる。git で管理しているファイルだけをコピーした、clone 直後と同じ状態から `make test dev` が動くことを確認した。

## 計測

### コード単位の受け渡しにかかる時間

Workers の中では、Spectre 対策で `Date.now()` や `performance.now()` が処理の途中で進まない（I/O を待つまで止まっている）ので、Worker の中では計れない。そこで、同じ V8 で動く Node.js 24 で、`worker.mjs` と同じ受け渡しの処理を書いて測った。

計測用に、一時的なコピーへ次の 2 つを足した（リポジトリには入れていない）。

- `/big`：600 段落、40,195 コード単位（UTF-8 で 50,995 B）の HTML を返すページ。
- `bench_render`：`render` だけを実行し、本文の長さを返す export。JS との受け渡しをしない。

| ページ | `render` だけ（Wasm の中） | `serve` で受け渡しまで | 受け渡しの割合 |
| --- | --- | --- | --- |
| `/`（148 コード単位、`put` 184 回） | 0.3〜0.4 µs | 1.5 µs | 約 8 割 |
| `/big`（40,195 コード単位、`put` 40,231 回） | 79〜87 µs | 369〜446 µs | 約 8 割 |

`/big` は 3 回測った範囲。受け渡しのコストは、コード単位の数（= `put` の呼び出し回数）に比例する。割合は大きいが、50 KB のページでも 0.5 ms を切る。Workers の無料プランの CPU 時間の上限（10 ms）に比べても十分小さいので、今のところ UTF-8 のバイト列を線形メモリ越しにまとめて渡す ABI に切り替える必要はない。ページが数百 KB になる、あるいは 1 リクエストで何度も呼ぶようになったら考え直す。

`wrangler dev` に `curl` を 20 回送った往復時間（中央値）も、`/` が 1.0 ms、`/big` が 1.8 ms で、差は 1 ms 程度だった。

### `wasm-opt`

binaryen の `wasm-opt`（version 132、`npx -p binaryen` で実行）をかけた。

| ビルド | サイズ | gzip -9 |
| --- | --- | --- |
| `moon build --release` そのまま | 5,279 B | 2,744 B |
| `wasm-opt -O3` | 4,752 B | 2,266 B |
| `wasm-opt -Oz` | 4,021 B | 2,110 B |

`-Oz` で 24% 小さくなり、最適化後の Wasm も同じ応答を返した。ただし gzip 後の差は 600 B ほどなので、ビルドの依存（binaryen）を増やしてまで入れてはいない。ブログ全体を移植して Wasm が大きくなったら、もう一度測る。

`wasm-opt` に渡す機能の指定には注意が要る。

- `-all` だと、V8 がまだ対応していない機能も有効になり、出力が読み込めなくなる（`invalid heap type 'exact'`、`--disable-custom-descriptors` を足しても `unknown import kind 0x7e`）。
- `--enable-gc --enable-reference-types --enable-bulk-memory --enable-sign-ext --enable-nontrapping-float-to-int --enable-mutable-globals --enable-multivalue` と、使う機能だけを指定すると通った。

## Go 版との比較スクリプト

ブログを移植するあいだの物差しとして、Go 版のブログと MoonBit の Worker に同じパスを取りにいき、ステータス、`Content-Type`、本文を比べる CLI を MoonBit で書いた（`moonbit/compare`）。`make compare` で動く。

- 比べる処理（`compare` パッケージ）はターゲットを問わない純粋な関数にして、`moon test` で確かめている。本文の差分は core の `@diff`（Myers 法）で取る。Go 版はページの大半を 1 行に書くので、行単位だとページ全体が 1 つの変更になってしまう。そこで、改行と `>` の後ろで区切った単位で比べる。
- HTTP の取得は `moonbitlang/async@0.22.5` の `@http.get` を使う実行ファイル（`compare/cmd`）に分けた。async の I/O は native でしか動かないので、`compare/cmd` は `supported_targets = "+native"`、ホストの import が native でコンパイルできない `worker` は `"+wasm-gc"` にした。これで、`moon.mod` に async を足しても Worker の Wasm は 5,279 B のまま、バイト単位で変わらない（export は `path_push` と `serve`、import は `host` の 4 つのまま）。`make check` には `moon check --target native` を足した。
- `@http.get` はリダイレクトを追わないので、リダイレクトはそのまま比べられる。
- `/`、`/posts/hello`、`/docs/ja/design`、`/docs/`、`/favicon.svg`、`/no-such-page` を既定のパスにした。Go 版は `go generate` で `TODO.md` と `docs/` をコピーしてから起動しないと文書を返さない。

今の結果は、予想どおり 6 つとも違う。

| パス | 違うところ |
| --- | --- |
| `/` | 本文 |
| `/posts/hello` | ステータス（Go 200、MoonBit 404）、本文 |
| `/docs/ja/design` | ステータス（Go 200、MoonBit 404）、本文 |
| `/docs/` | ステータス（Go 200、MoonBit 404）、本文 |
| `/favicon.svg` | ステータス、`Content-Type`（Go `image/svg+xml`、MoonBit `text/html; charset=utf-8`）、本文 |
| `/no-such-page` | 本文（どちらも 404） |

Go 版どうしを比べると 6 つとも `same` になり、終了コードは 0 だった。

## 記事の埋め込み

MoonBit に `go:embed` はないが、`moon.pkg` の `rule` と `dev_build` で、`moon check`・`moon build`・`moon test` の前にコマンドを実行してソースを生成できる（moon 0.1.20261012 で確認）。組み込みの `:embed`（`moon tool embed`）は 1 ファイルを 1 つの `String` にするだけなので、`go/examples/blog/posts/*.md` をまとめて `(ファイル名, 本文)` の配列にするスクリプト `moonbit/scripts/embed.sh` を書き、本文の変換には `moon tool embed --text` を使った。生成先の `moonbit/posts/embedded.mbt` は git に入れない。

試して分かったこと。

- `dev_build` の `input` と `output` は、ドキュメントにある module のルートではなく、パッケージのディレクトリからの相対パスとして解決される。コマンドは module のルートで実行され、`$input` は `./../go/...` の形で渡る。`output` をパッケージの外に置くと、コンパイル対象に入らないという警告が出る。
- `input` には配列も書けるが、glob（`*.md`）は使えない（そのままのファイル名として探して missing になる）。ディレクトリを渡すと、ディレクトリの mtime しか見ないので、記事の追加と削除では再生成されるが、既存の記事の編集では再生成されない。
- そこで `make build`・`make test`・`make check` からも毎回スクリプトを実行する（内容が変わったときだけ書き換えるので、変わらなければ再ビルドは起きない）。wrangler のビルドコマンドは `moon build` から `make build` に変え、`watch_dir` に記事のディレクトリを足した。`make dev` 中に記事を編集すると、再ビルドで `embedded.mbt` が更新されることを確かめた。
- まだ `site` から使っていないので、Worker の Wasm は 5,279 B のまま変わらない。試しに `site` から 1 記事を出力すると 15,687 B になり、記事の編集が `make build` で Wasm に反映された。
- clone した直後（`embedded.mbt` がない状態）から、`make build` も素の `moon test` も通る。

## HTML ビルダー（`el`）

Go 版の `pkg/el` を `moonbit/el` に移植した。`picoel` はまだ。

- **ノード**：Go の `Node` インターフェースと 5 つの型は、閉じた `enum Node`（`Text`、`Raw`、`Element`、`Attr`、`BoolAttr`）にした。要素名と属性名は、Go と同じく別の型（タプル構造体 `Tag(String)` と `AttrName(String)`）にしてあり、取り違えるとコンパイルが通らない。`derive(Eq, Debug)` で `==` と `assert_eq` が使える。
- **名前の定数**：`const` はプリミティブ型にしか使えず、大文字で始める決まりなので、`pub let div : Tag = Tag("div")` のように小文字の値にした。MoonBit のキーワードと重なる属性は、`title_attr` と同じく `_attr` を付けた（`defer_attr`、`type_attr`）。
- **レンダリング**：Go の `Renderer` インターフェースと `Render` の型スイッチは、`render_html` と `render_plain` の 2 つの関数の `match` にした。`enum` は閉じているので未知のノードはなく、出力先は `StringBuilder` なので書き込みエラーもない。Go のテストのうち、`nil` の子、未知のノード、書き込みエラーの 3 つはこのため移植していない。それ以外のケースは `moon test` で同じ出力を確かめている。
- **エスケープ**：`html.EscapeString` と同じく、`"` を `&#34;`、`'` を `&#39;` にする。`site` の今のエスケープは `&quot;` を使っているので、`el` に乗り換えるときに出力が Go 版にそろう。
- **警告 `implicit_impl_as_method`**：moonc v0.10.15 では、公開した型に `derive(Eq, Debug)` を付けるだけで、`equal` などがメソッドに昇格することへの警告が出る。core（`cmp/extends.mbt`）にならい、`#deprecated` を付けた `pub extend ... with Eq::{equal, not_equal}` を書いて消した（`el/extends.mbt`）。
- `worker` はまだ `el` を使っていないので、Wasm は 5,279 B のまま。

## Markdown の移植

`go/pkg/tinymarkdown` を `moonbit/tinymarkdown` に移植した（`pkg/tinyfrontmatter` はまだ）。

- **構文木**：Go の `Block` / `Inline` インターフェースと構造体は、MoonBit の enum 1 つずつにした（`Section(level~, title~, children~)`、`Paragraph(String)` など）。`derive(Eq, Debug)` で比べて表示できる。見出しを入れ子にする前の平らな列は、Go では非公開の `heading` 型を `Block` に混ぜていたが、MoonBit では非公開の enum `Flat`（`Block(Block)` と `Heading(Int, String)`）で表した。
- **インデックス**：Go は文字列をバイトで、MoonBit は UTF-16 のコード単位で数える。パーサーが探す文字はすべて ASCII なので、同じ位置で切れる。`` s[i] == '`' `` のように、コード単位と文字リテラルをそのまま比べられる。
- **空白の除去**：`String::trim()` の既定は `"\t\n\r "` だけで、Go の `strings.TrimSpace`（`unicode.IsSpace`、U+00A0 なども含む）より狭い。同じ文字の集合を定数にして `trim(chars=...)` に渡した。
- **derive の警告**：公開する型に `derive(Eq, Debug)` を付けると、生成したメソッドが暗黙にメソッドになるのは非推奨だという警告（`implicit_impl_as_method`）が出る。公式ドキュメントの例と同じく `pub extend Block with Eq::{not_equal, equal}` と `pub extend Block with Debug::{to_repr}` を書いた。`pub` を付けない `extend` では、今度は未使用の警告が出る。
- **テスト**：Go のテストのケース（`Parse` 57 件、`Inlines` 31 件）を、名前、入力、期待する構文木の組の表として `moon test` に移した。手で書き直すと間違えるので、Go のリテラルを読んで MoonBit のリテラルに変換する使い捨てのスクリプトで生成し、件数を Go と比べた。Go と同じく、違うケースをすべて名前つきで報告する。`assert_eq` に `msg` を渡すと差分の表示が消えるので、`@debug.to_string` で got と want を自分で出している。
- **サイズ**：`worker` はまだ `tinymarkdown` を使わないので、Wasm は 5,279 B のまま。

## 記事

`/` と `/posts/{slug}` を、Go 版のブログと同じレイアウトで返すようにした。比較スクリプトで、`/`、4 つの記事、存在しない記事と存在しないパス（どちらも 404）の 7 つが Go 版と一致した。

- **移植したもの**：Go 版の `internal/site` の `posts.go`、`views.go`、`links.go`、`docs.go` のうち、記事のページに要る部分。記事が `docs/` の文書にリンクしているので、リンクの解決（`linker`）と文書の読み込みもこの段階で移した。文書のページは次の段階。
- **`net/url` と `path`**：リンクの解決は Go の `url.Parse`、`URL.String`、`path.Join` に頼っている。MoonBit の core にはないので、使う部分だけを書いた（スキームの判定、`%XX` の解釈と書き出し、`path.Clean`）。Go の `links_test.go` のケースに、エスケープや `url.Parse` が失敗する入力のケースを足して確かめている。`//` の後の authority の検査は移していない。
- **日付**：core に時刻の型がないので、日付はファイル名の `YYYY-MM-DD` の文字列のまま持ち、`time.Parse` と同じ言葉（`month out of range` など）で月と日を確かめる。並べ替えも文字列の比較でできる。
- **`site.css` のハッシュ**：Go 版はページに `/site.css?v=<SHA-256 の先頭 4 バイト>` を書く。core に SHA-256 がないので、`scripts/embed-assets.sh` がビルドの前に `sha256sum`（なければ `shasum -a 256`）で計算し、`site.css` と `favicon.svg` と一緒に `assets/embedded.mbt` に書く。
- **`BASE_URL`**：Go 版の Worker と同じく `wrangler.jsonc` の `vars` に置き、`worker.mjs` が最初のリクエストで `path_push` と新しい export の `set_base_url` で Wasm に渡す。記事は最初の `serve` で読み込み、読み込めなければすべてのリクエストに理由を書いた 500 を返す。比較では Go 版を同じ `-base-url` で起動する。
- **文字列の比較**：`String::compare` は短い文字列を先に並べるので、Go と同じ順にするには `lexical_compare` を使う。
- **サイズ**：記事と文書（`TODO.md` と `docs/`）をすべて埋め込んだので、Wasm は 205,578 B（gzip で 68,092 B）になった。埋め込んだソースは合わせて約 124 KB。

## 文書とリンク

`/docs/` と `/docs/{path}` を返すようにした。リンクの解決と文書の読み込みは記事の段階で移してあったので、足したのは文書の一覧と文書のページ、`/docs/` の下の経路だけだった。比較スクリプトで、`/docs/`、6 つの文書（`TODO.md` と `docs/**/*.md`）、存在しない文書が Go 版と一致した。文書の中の相対リンク（`/docs/` や `/posts/` のページへ、GitHub へ、リンクにしない）も、本文の比較に含まれている。

- Go 版は `go generate` で文書をコピーしてから埋め込むので、文書を編集したら、比較の前に Go 版でも `go generate ./...` をやり直す必要がある。やり直さないと、古いコピーとの差分が出る。

## 残りのルート

`/favicon.svg`、`/site.css`、記事と文書の `.md` 版、リダイレクト（正規化されていないパスと `/docs` から `/docs/`）、404 ページを足し、Go 版のブログのルートをすべて移した。

- **比較**：Go 版の `/` と `/docs/` からたどれるすべてのページとその `.md` 版、`/favicon.svg`、`/site.css`（`?v=` 付きと無し）、`/docs`、`/docs?x=1`、`//posts/hello`、存在しない記事・文書・パスとその `.md` 版、Go 版の `-watch` 用のパス（`/_livereload.js` など、どちらも 404）の 41 パスを比べ、40 パスが一致した。
- **一致しない 1 パス**：`/docs/ja/../TODO` のように `.` や `..` を含むパスは、Go 版が 307 で `/docs/TODO` にリダイレクトするのに対し、Worker は 200 で `/docs/TODO` を返す。workerd がリクエストを受けた時点で URL を正規化するので（wrangler のログにも正規化後のパスが出る）、`request.url` にも元のパスは残っておらず、Worker の側では区別できない。Wasm の `render` は Go 版と同じくリダイレクトを返し、`moon test` で確かめている。
- **リダイレクトの本文**：Go の `http.Redirect` は GET に `<a href="...">Temporary Redirect</a>.` と改行 2 つの本文を付ける。比較は本文も見るので、同じ本文を返す。`Location` のクエリーを保つため、`worker.mjs` はクエリーを新しい export の `set_query` で渡す。
- **メソッド**：Go 版は GET と HEAD 以外に 404 を返すが、Worker はメソッドを見ずに同じ応答を返す。比較は GET だけで行う。

## 次の一歩

1. （済み）トップレベルに `moonbit/` を作り、spike の ABI と `worker.mjs` を置く。「`moonbit/` への取り込み」の節を参照。
2. （済み）ステータスとヘッダーを返せるように ABI を広げ、存在しないパスに 404 を返す。「ステータスとヘッダー」の節を参照。
3. （済み）`moonbit/Makefile` に `build`、`test`、`dev`、`deploy` を用意する。「Makefile」の節を参照。
4. （済み）本番に `blog-moonbit` としてデプロイし、wasm-gc が受け付けられるかを確かめて、アップロードサイズを追記する。「デプロイ」の節を参照。
5. （済み）`wasm-opt -Oz` をかけたサイズと、コード単位の受け渡しにかかる時間を測る。「計測」の節を参照。
6. （済み）Go 版のブログと、パスごとにステータス、`Content-Type`、本文を比べる CLI を `moonbit/compare` に置く。「Go 版との比較スクリプト」の節を参照。
7. ブログ全体を移植し、Go 版とサイズを比べて、このレポートに追記する。手順は TODO.md の「Reimplement the blog in MoonBit」の子タスクに分けた（Go 版との比較スクリプト、記事と文書の埋め込み、HTML ビルダー、Markdown、記事、文書とリンク、残りのルート、比較と記録）。

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
