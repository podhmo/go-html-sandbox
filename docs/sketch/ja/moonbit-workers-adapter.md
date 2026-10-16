# 探索メモ: MoonBit の Workers 用アダプターを磨く

TODO.md の「MoonBit の Workers 用アダプターを最適な形に磨く」の探索の記録（2026-10-16）。
今のアダプター（`moonbit/workers/worker.mjs`、`moonbit/worker` の export、host の import）に代わる形を、`/tmp` の spike でいくつか作って比べた。
案ごとに結果を確かめてから、どれを取り込むか決める。案 D' と案 G は取り込んだ（「取り込み」の節）。

前提となる経緯は[調査メモ](moonbit-workers-wasm.md)にある。このメモは、次の探索でもそのまま使えるように、分かった前提、試した案のすべて、確かめられなかったことを分けて書く。

## 結論（暫定）

- **受け渡しは、Wasm の線形メモリに UTF-8 でまとめて書く形（案 D'）がいちばん速い。** いちばん大きいページ（53,784 B）で、1 リクエストが約 740 µs から約 390 µs になった。受け渡しのコストは約 390 µs から約 50 µs に減り、残りのほとんどは Wasm の中の `render`（約 340 µs）になる。
- その形にすると、export は `serve` と `memory` の 2 つ、import は 0、`worker.mjs` は 65 行から 31 行になる。`set_base_url`、`set_query`、`path_push` と、`host` の 4 つの import はいらなくなる。
- **`wasm-opt -Oz` は、moon に同梱の `moon-wasm-opt` で依存を増やさずにかけられる。** 255,859 B が 237,559 B（-7%）、gzip 後は 83.5 KB が 76.5 KB になり、速さは変わらないか少し速い。
- **workerd に、js-string builtins を有効にする互換性フラグ `wasm_esm_integration_builtins` が 2026-10-12 に入った**（後述）。これを使う案 E は `worker.mjs` が 23 行でいちばん短く、Wasm もいちばん小さい（231,619 B）が、Node で測ると案 D' より遅い（約 540 µs）。手元の wrangler ではまだフラグを使えず、Workers の上では確かめられていない。
- 推す順番: 案 D' + `-Oz` + メソッドを Wasm に渡す（案 G）。案 E はフラグを試せるようになったら測り直す。

## 環境

| | バージョン |
| --- | --- |
| moon | 0.1.20261012 |
| moonc | v0.10.15 |
| moon-wasm-opt | binaryen version 125（moon のツールチェーンに同梱。`~/.moon/bin/moon-wasm-opt`） |
| Node.js | 24.21.0 |
| wrangler | 4.148.0（`npx wrangler@4`）、同梱の workerd は 1.20261006.1 |

spike は `git archive HEAD` で `/tmp/go-html-sandbox/adapter` に取り出したコピーに、案ごとのパッケージ（`worker_packed`、`worker_mem16`、`worker_utf8`、`worker_utf8d`、`worker_jsstr`）と `workers/worker-<案>.mjs` を足して作った。`/tmp` なので残らない。要点のコードは末尾に載せた。

## 分かった前提

### MoonBit 側

- **wasm-gc の出力にも線形メモリがある。** `moon build --output-wat` で見ると `(memory $moonbit.memory 1)` があり、何も読み書きしていない（`i32.load` / `i32.store` が 1 つもない）。link 設定の `"export-memory-name": "memory"` で export できる。
- **inline wasm で線形メモリを読み書きできる。** `extern "wasm" fn store8(addr : Int, v : Int) = #|(func (param i32) (param i32) (i32.store8 (local.get 0) (local.get 1)))` のように書くと、wasm-gc でも `i32.load8_u`、`i32.store16`、`memory.size`、`memory.grow` が使えた。ただし、moon が将来この 1 ページを自分で使い始めたら壊れる（今は使っていない、というだけ）。
- **`method` は予約語。** `Site::render` に `method~` という引数を足すと `reserved_keyword` の警告が出る（「将来のために予約」）。spike では `verb~` にした。
- **wasm-gc の link 設定には `imported-string-constants` がある**（[package の設定](https://docs.moonbitlang.com/en/latest/toolchain/moon/package.html)）。`use-js-builtin-string` の文字列定数を import する名前空間で、既定は `"_"`。`"wasm:js/string-constants"` にすると、workerd のフラグが決め打ちしている名前空間に合わせられる。
- **builtin string にすると、埋め込んだ文章が文字列定数の import 名になる。** 案 E の Wasm は import が 221 個（`wasm:js/string-constants` が 215、`wasm:js-string` の `length`、`charCodeAt`、`equals`、`concat`、`fromCodePoint`、`fromCharCodeArray`）で、いちばん長い import 名は 23,369 文字。それでも Wasm は 24 KB ほど小さくなる。

### JS / Workers 側

- **`memory.grow` のあと、前の `memory.buffer` は detach される。** `new Uint8Array(memory.buffer, 0, serve(n))` と書くと、引数の評価順で `memory.buffer` を先に読むので、`serve` の中でメモリが増えると `TypeError: Cannot perform Construct on a detached ArrayBuffer` になる。`serve` の戻り値を先に変数に取る。いちばん大きいページ（53,784 B）は初期の 1 ページ（64 KiB）に収まるので、Wasm がメモリを多めに確保するまでこの誤りに気づかなかった。
- **Workers では、どの案でも本文は chunked で返る。** `wrangler dev` では、本文を文字列で渡しても `Uint8Array` で渡しても `Transfer-Encoding: chunked` になり、`Content-Length` は付かない。Go 版のサーバーは `Content-Length: 1877` を付ける。`make compare` はこれを比べないので一致する。本番の Cloudflare の前段で変わるかは見ていない。
- **HEAD**: `wrangler dev` では、どの案でも HEAD に本文が付かない。Go 版と同じく `Content-Type` が付く。
- **メソッド**: 今の Worker は POST にも 200 で同じページを返す。Go 版は GET と HEAD 以外に 404 の「Page not found.」を返す。メソッドを Wasm に渡す案（C、D、D'、E）は、本文まで Go 版と一致した。
- **壊れた `%` エスケープ**: `/%E0%A4%A` はどちらも 400（本文は違う。Go 版は `400 Bad Request`、Worker は `Bad request: malformed path`）。**`/%FF` は Go 版が 404、Worker は 400。** `%FF` は形の上では正しいエスケープだが UTF-8 として不正なので、`decodeURIComponent` が投げる。全案に共通の違いで、`make compare` の既定のパスには入っていない。その後、案 H で直した。
- **workerd による URL の正規化**（`/docs/ja/../TODO` が届く前に `/docs/TODO` になる）は、どの案でも変わらない。アダプターの側では直せない。
- `wrangler dev` の往復時間は、どの案も `/` が約 1.1 ms、いちばん大きいページが 1.5〜1.8 ms で、案の差（0.3 ms 程度）はばらつきに埋もれる。案の比較は Node で行った。
- Node の `Request` / `Response` を作って本文を読むだけの Worker（Wasm を呼ばない）は、1,732 文字の本文で 6 µs、36,670 文字で 22 µs かかる。以下の Node の数字にはこれが含まれる。

### 測り直して分かったこと

- **いちばん大きいページの `render` は、Wasm の中だけで約 345 µs かかる**（Markdown の解析を含む）。前の調査の `/big`（80 µs 前後）は段落を並べただけの合成ページだったので、実際のページはそれより重い。受け渡しを速くすると、残りのほとんどは `render` になる。
- `/` の `render` は約 10 µs。

## 案

| 案 | 受け渡し | export / import | `worker.mjs` | 状態 |
| --- | --- | --- | --- | --- |
| A（今） | コード単位を 1 つずつ（`path_push`、`host.put`） | 4 / 4 | 65 行 | 基準 |
| B | 出力だけ、1 回の import で 8 コード単位（i32 4 つに 2 つずつ詰める） | 4 / 5 | 66 行 | 試した |
| C | 線形メモリに UTF-16 で書き、JS は `TextDecoder("utf-16le")` | `serve` + `memory` / 0 | 29 行 | 試した |
| D | 線形メモリに UTF-8 で書く。MoonBit は `@utf8.encode` してから 1 バイトずつコピー | `serve` + `memory` / 0 | 31 行 | 試した |
| D' | D と同じ。UTF-8 を線形メモリに直接書く | `serve` + `memory` / 0 | 31 行 | 試した（推す） |
| E | `use-js-builtin-string`。JS の文字列をそのまま渡す | `serve` / 221（すべてランタイムが解決） | 23 行 | Node でだけ試した |
| F | `moon-wasm-opt -Oz` をビルドに入れる | — | — | 試した（推す） |
| G | メソッドを Wasm に渡し、GET と HEAD 以外は 404 | — | — | C〜E に入れて試した |
| H | パスのデコードを Wasm でする | — | — | 取り込んだ |
| I | 応答を isolate の中でキャッシュする | — | — | 取り込んだ |
| J | MoonBit の `js` バックエンドにする | — | — | 対象外 |

### C、D、D' に共通の形

- 入力は 1 つの文字列 `BASE_URL\nmethod\nquery\npath` にして、JS がメモリの先頭に書き、`serve(長さ)` を呼ぶ。パスは最後に置くので、デコードした結果に改行が入っても困らない（最初の 3 つの改行だけで区切る）。クエリーは `url.search` のままなので改行を含まない。
- 出力は `status\nname\tvalue\n...\n\n` と本文を、同じ場所に上書きする。`serve` は長さを返す。ヘッダーの名前と値は改行を含まない。
- `BASE_URL` を毎回渡すので、`set_base_url` と、JS 側の「前に渡した値」の状態がいらない。Wasm は前の値と違うときだけ `Site` を作り直す。
- メモリが足りなければ、入力は JS が `memory.grow`、出力は Wasm が `memory.grow` する。
- D と D' は本文を `Uint8Array` のまま `Response` に渡すので、JS の文字列を作らない。ヘッダーの部分だけ `TextDecoder` で文字列にする。

### E（builtin string）について

- **workerd の [PR #7685](https://github.com/cloudflare/workerd/pull/7685)（2026-10-12 マージ）で、互換性フラグ `wasm_esm_integration_builtins` が入った。** `import` した Wasm を `new WebAssembly.Module(src, { builtins: ['js-string'], importedStringConstants: 'wasm:js/string-constants' })` と同じ設定でコンパイルする。提案がまだ実装段階なので、有効になる日付はなく、明示的に付ける必要がある（`compatibility-date.capnp` には `$experimental` の印はなかった）。[調査メモ](moonbit-workers-wasm.md)の「Workers ではコンパイルのオプションが効かない」は、このフラグで変わる可能性がある。
- 文字列定数の名前空間は `wasm:js/string-constants` に決め打ちなので、MoonBit 側で `"imported-string-constants": "wasm:js/string-constants"` を指定した。
- Node で同じオプションを付けてコンパイルすると、35 パスの出力が案 A と一致した。
- 遅い理由: builtin string にすると、MoonBit の文字列の操作が JS の関数の呼び出しになるので、`render` そのものが約 345 µs から約 409 µs に遅くなる。さらに、`StringBuilder` の `to_string` と本文の連結で文字列を作り直す。
- 利点: アダプターがいちばん単純になり（inline wasm も線形メモリもいらない）、Wasm もいちばん小さい。

### 試していない案

- **H（パスのデコードを Wasm で）**: その後、取り込んだ（「取り込み（案 H）」の節）。
- **I（応答のキャッシュ）**: その後、取り込んだ（「取り込み（案 I）」の節）。Cache API（`caches.default`）を使う形は試していない。
- **J（`js` バックエンド）**: Workers 用の MoonBit ライブラリとして [mizchi/cloudflare](https://github.com/mizchi/cloudflare.mbt)（mooncakes.io の `mizchi/cloudflare` 0.1.13、KV、D1、R2 などのバインディング）が見つかった。前の調査では見つからなかったもの。ただし `moon.mod` は `preferred_target = "js"`、各パッケージは `supported_targets = "js"` で、`mizchi/js_*` に依存する **JS にコンパイルするためのライブラリ**であり、Wasm では使えない。このブログは Wasm で動かすこと自体が目的（ロマン）なので、対象外とする。Wasm 向けで Workers に使える MoonBit のライブラリは、今回も見つからなかった（mooncakes.io の一覧 3,029 件を `cloudflare`、`workers`、`workerd` で検索した）。

## 計測

### Node での処理時間

`worker-<案>.mjs` の `fetch` に `Request` を渡し、`Response` の本文を読み終えるまで。各案を 1,000 回 × 5 回測った中央値を、2 回実行した範囲で書く。どの案も、35 パス（`/`、`/docs/` からたどれる記事と文書とその `.md` 版、`/favicon.svg`、`/site.css`、存在しないパスなど）で、ステータス、ヘッダー、本文が案 A と一致することを先に確かめた。

| 案 | `/`（1,732 コード単位） | いちばん大きいページ（`/docs/sketch/ja/moonbit-modernize`、53,784 B、36,670 コード単位） |
| --- | --- | --- |
| A（今） | 31〜34 µs | 727〜766 µs |
| A + `-Oz` | 32 µs | 688〜796 µs |
| B | 29 µs | 643〜651 µs |
| C | 22〜29 µs | 445〜503 µs |
| D | 21〜23 µs | 419〜438 µs |
| D' | 20 µs | 393〜435 µs |
| D' + `-Oz` | — | 381〜383 µs |
| E | 22〜25 µs | 543 µs |
| 参考: `render` だけ（Wasm の中、wasm-gc） | 10 µs | 345 µs |
| 参考: `render` だけ（builtin string） | 11 µs | 409 µs |

- 受け渡しにかかる時間（全体 −`render` − Node の `Response` の約 20 µs）は、A が約 390 µs、B が約 280 µs、C が約 100〜140 µs、D' が約 30〜70 µs。
- B のように 1 回の呼び出しで運ぶ量を増やしても、呼び出しの回数が 1/8 になるほどには速くならない。JS の配列に積んで `String.fromCharCode` する部分が残る。

### サイズ

| 案 | Wasm | gzip -9 | `wrangler deploy --dry-run` の Total Upload |
| --- | --- | --- | --- |
| A（今、リポジトリそのまま） | 255,546 B | — | — |
| A（spike。`Site::render` に `verb~` を足した分 +313 B） | 255,859 B | 83,526 B | 251.57 KiB（gzip 82.86〜83.06 KiB） |
| A + `-Oz` | 237,559 B | 76,505 B | — |
| B | 256,213 B | 83,705 B | — |
| C | 255,882 B | 83,517 B | 251.08 KiB（gzip 82.86 KiB） |
| D | 256,584 B | 83,774 B | 251.77 KiB（gzip 83.10 KiB） |
| D + `-Oz` | 238,135 B | 76,908 B | 233.76 KiB（gzip 76.25 KiB） |
| D' | 257,031 B | 83,933 B | — |
| D' + `-Oz` | 238,388 B | 77,003 B | — |
| E | 231,619 B | 81,981 B | — |
| E + `-Oz` | 212,465 B | 74,857 B | — |

- アダプターの違いによるサイズの差は 1 KB 前後で、ほとんどが埋め込んだ文章。サイズを決めるのは `-Oz` と、[文章を Wasm の外に出す TODO](moonbit-static-assets.md) のほう。
- `moon-wasm-opt` に渡す機能の指定は、前の調査と同じく `-all` だと V8 で読めない（`invalid heap type 'exact'`）。`--enable-gc --enable-reference-types --enable-bulk-memory --enable-sign-ext --enable-nontrapping-float-to-int --enable-mutable-globals --enable-multivalue` で通る。E には `--enable-strings` も足した。
- zsh では、この機能の一覧を変数に入れて `$OPT $FEAT` と渡すと、単語に分割されずに 1 つの引数になる（`Unknown option`）。`bash -c` で実行した。

### Go 版との比較

C、D、A のそれぞれを `wrangler dev` で動かし、ローカルの Go 版（`-base-url https://blog.podhmo.workers.dev`）と `make compare` で比べた。既定の 6 パスと、上の 35 パスに `//posts/../`、`/docs?x=1`、`/site.css?v=...` などを足した 41 パスが、3 つとも一致した。D' と E は `wrangler dev` では比べておらず、Node での案 A との一致だけを確かめた（D' は D と JS が同じで、Wasm の UTF-8 の書き方だけが違う）。

## 確かめられなかったこと、アクセスできなかったもの

次の探索では、ここから再開できるかもしれない。

- **`wasm_esm_integration_builtins` を `wrangler dev` で試せなかった。** 手元の wrangler 4.148.0（workerd 1.20261006.1）では、`compatibility_flags` に書くと `No such compatibility flag: wasm_esm_integration_builtins` で workerd が起動しない。フラグが入ったのは 2026-10-13 公開の workerd 1.20261013.1 以降で、最新の wrangler は 4.151.0。しかし npm の設定 `min-release-age = 8` で、公開から 8 日たっていない版は入らない（`No matching version found for wrangler@4.151.0 with a date before 2026/10/8`）。この設定は依存の取り込みを遅らせるための意図的なものなので、迂回していない。**2026-10-21 ごろ以降なら、フラグ入りの wrangler を入れて試せる見込み。**
- **本番の Workers でこのフラグが使えるかは確かめていない。** 本番のランタイムに入る時期は分からない。確かめるにはデプロイが要る。
- **案ごとの本番での起動時間（Worker Startup Time）は測っていない。** spike の段階では `wrangler deploy --dry-run` で Total Upload だけを取った。取り込んだ案 D' と main のアダプターは、その後 `make deploy` で測った（「取り込み」の節）。
- **workerd の中での CPU 時間を測っていない。** Workers の中ではタイマーが I/O まで進まないので、前の調査と同じく Node で代わりに測った。本番の CPU 時間は、デプロイして Workers のダッシュボードかログ（`cpuTime`）で見られるかもしれない。
- **案 D' と E を Go 版と `make compare` で比べていない**（上の「Go 版との比較」）。
- **workerd の正式なドキュメントでのフラグの説明**は見つからなかった。Web 検索では Cloudflare の [Wasm のドキュメント](https://developers.cloudflare.com/workers/runtime-apis/webassembly/)にも builtins の話はなく、workerd のソース（`src/workerd/io/compatibility-date.capnp`）と PR を `gh` で読んで分かった。[互換性フラグの一覧](https://developers.cloudflare.com/workers/configuration/compatibility-flags/)に載ったかは、次に確かめる。

## 取り込み（案 D' と案 G）

2026-10-16 に、案 D'（線形メモリに UTF-8 で書く）と案 G（メソッドを渡す）を `moonbit/worker`、`moonbit/workers/worker.mjs`、`Site::render` に取り込んだ。`-Oz` はまだ入れていない。

- `worker` は、線形メモリの読み書き（inline wasm と UTF-8 の読み書き）を `memory.mbt` に、`BASE_URL` ごとの `Site` の読み込みと要求の解釈を `worker.mbt` に置いた。export は `serve` と `memory`、import は 0。
- `Site::render` に `verb~`（既定は `"GET"`）を足し、GET と HEAD 以外には、リダイレクトより先に 404 のページを返す。Go 版の `route` と同じ順番。`moon test` で確かめている。
- 要求の 4 つの欄がそろわないとき（JS の誤りでしか起きない）は 400 を返す。

### 確かめたこと

- `make check` が通る（62 テスト）。
- `make dev` と、ローカルの Go 版（`-base-url https://blog.podhmo.workers.dev`）を `make compare` で比べた。既定の 6 パス、`/` と `/docs/` からたどれる記事と文書（このメモを含む）とその `.md` 版、`/favicon.svg`、`/site.css`（`?v=` 付きと無し）、`/docs`、`/docs?x=1`、`//posts/../`、`/_livereload.js`、存在しないパスの 42 パス、日本語を含むパスとリダイレクト 4 つが、すべて一致した。
- POST の `/posts/hello` と `/docs` は、Go 版と同じく 404 で、本文も一致した。
- `make deploy` で `blog` にデプロイし、公開中の `https://blog.podhmo.workers.dev` と Go 版を 43 パスで比べて、すべて一致した。POST は 404 になった。

### 比べた数字

比べる相手は、同じ文書（このメモを含む）を埋め込み、`worker` と `worker.mjs` だけを main のものに戻したビルド。`Site::render` は両方とも `verb~` を足したもの。

| | main のアダプター | 取り込んだアダプター |
| --- | --- | --- |
| export / import | 4 / 4 | 2（`serve`、`memory`）/ 0 |
| `worker.mjs` | 65 行 | 34 行 |
| Wasm | 290,116 B（gzip -9 後 92,561 B） | 291,380 B（同 93,010 B） |
| wrangler の Total Upload | 285.01 KiB（gzip 後 91.84 KiB） | 285.74 KiB（gzip 後 92.05 KiB） |
| Worker Startup Time | 2 ms | 2 ms と 3 ms（2 回デプロイした） |
| `/`（Node） | 30 µs | 18 µs |
| いちばん大きいページ（Node、`/docs/sketch/ja/moonbit-modernize`、53,784 B） | 675〜678 µs | 355〜361 µs |

- Node の数字は、1,000 回 × 5 回の中央値を 2 回実行した範囲。最初は別の作業でマシンの負荷が高く（load average 41）、同じ測り方で main が 1.3〜1.7 ms、取り込んだ版が 0.6〜1.0 ms と大きくぶれた。負荷が下がってから測り直した値を載せた。負荷の高いときの数字は使わない。
- 起動時間は ms 単位でしか出ないので、差は見えない。
- Wasm は、UTF-8 の読み書きのぶん 1.3 KB 大きくなった。

## 取り込み（案 F、`-Oz`）

`make build` で、`moon build` の後に `moon-wasm-opt -Oz` をかけ、結果を `workers/build/app.wasm` に書くようにした。wrangler のビルドコマンドは `cd .. && make build` だけになった（前は `make build` の後に Wasm をコピーしていた）。機能の指定は「サイズ」の節のもの（`-all` は使わない）。`moon-wasm-opt` は moon と一緒に入るので、依存は増えていない。

| | `-Oz` なし | `-Oz` |
| --- | --- | --- |
| Wasm | 295,510 B（gzip -9 後 94,215 B） | 276,914 B（同 87,289 B） |
| wrangler の Total Upload | — | 271.62 KiB（gzip 後 86.50 KiB） |
| Worker Startup Time | — | 3 ms |
| `/`（Node） | 17.5〜18.2 µs | 17.2〜17.3 µs |
| いちばん大きいページ（Node） | 346〜350 µs | 354〜356 µs |

- 文書がこのメモの分だけ増えたので、Wasm は「案 D' と案 G」の節より大きい。`-Oz` で 6.3% 小さくなった。
- 速さは変わらない（差はばらつきの範囲）。
- 起動時間は、このあいだのデプロイで 2 ms と 3 ms のどちらも出ており、ms 単位では差が分からない。
- `make dev` とローカルの Go 版、デプロイした `blog` とローカルの Go 版を、それぞれ 44 パスで比べ、すべて一致した。

## 取り込み（案 H、パスのデコード）

`worker.mjs` は `url.pathname` をエスケープしたまま渡し、Wasm が `site` の `unescape`（リンクの解決のために移植してあった `%XX` の解釈）でデコードするようにした。Go の net/http がハンドラーの前にすることを、Worker では `worker` パッケージがする。

- 形の壊れたエスケープ（`%zz`、`%E0%A4%A`、末尾の `%`）には、Go の net/http と同じ `400 Bad Request`（`text/plain; charset=utf-8`、改行なし）を返す。
- 形は正しいが UTF-8 でないバイト（`%FF`、`%C3%28`、サロゲートの `%ED%A0%80`）は U+FFFD に置き換えてルーティングに回す。Go 版は 404 の本文にパスを書かないので、404 は本文まで一致する。
- `worker.mjs` から `try` / `catch` がなくなり、29 行になった。

### Go 版との比較

44 パスに、変なエスケープを含む 14 パス（`/%FF`、`/posts/%FF`、`/docs/%FF`、`/posts/%FF.md`、`/%FF/`、`/%FF//`、`/a%00b`、`/%C3%28`、`/%ED%A0%80`、`/%E0%A4%A`、`/%zz`、`/docs%2F`、`/a%2Fb`、`/posts/hello%3F`）を足した 58 パスで比べた。

| 比べた相手 | 一致しないパス |
| --- | --- |
| 取り込む前（`decodeURIComponent`）の、デプロイした `blog` | 14 パスのうち 11 |
| 取り込んだ後の `make dev` | 58 パスのうち `/%FF//` の 1 つ |
| 取り込んだ後の、デプロイした `blog` | 58 パスのうち `/%FF//`、`/a%00b`、`/%zz` の 3 つ |

- **`/%FF//` は残る。** Go 版は `/%FF/` にリダイレクトするが、Wasm は U+FFFD に置き換えた後のパスを書くので `/%EF%BF%BD/` になる。MoonBit の `String` は不正な UTF-8 を持てないので、合わせるには、置き換えずに元のバイトを覚えておく仕組み（例えば Python の surrogateescape のように、バイト b を孤立したサロゲート U+DC00+b にして、リダイレクトの `escape` で `%XX` に戻す）が要る。UTF-8 でないパスが、さらに正規化されていない場合だけの違いなので、入れていない。
- **本番では、`/a%00b` と `/%zz` は Worker に届かない。** Cloudflare の前段が、HTML の `400 Bad Request` ページ（`server: cloudflare`、`content-type: text/html`）を返す。`wrangler dev` では Worker に届き、Go 版と一致する。`/%E0%A4%A` と `/%` は本番でも Worker に届き、Go 版と同じ本文を返す。どのエスケープを前段が止めるのかの規則は調べていない。
- デプロイした版の Total Upload は 273.08 KiB（gzip 後 86.86 KiB）、Worker Startup Time は 2 ms。

## 取り込み（案 I、応答のキャッシュ）

`worker.mjs` が、GET と HEAD への 200 の応答を、エスケープしたままのパスごとに isolate の `Map` に持ち、2 回目からは Wasm を呼ばずに返すようにした。

- **なぜパスだけをキーにしてよいか**: 内容は Wasm に埋め込んであり、isolate の中では変わらない。クエリーが応答に効くのはリダイレクト（307）の `Location` だけで、200 の応答には効かない。`/site.css?v=...` のように任意のクエリーが付いても、キーは増えない。
- **200 だけ**: 404 は存在しないパスの数だけ増えうるので持たない。リダイレクトはクエリーで変わるので持たない。POST などは 404 なので持たない。
- **上限**: 同じパスでも `/posts/hell%6F` のようにエスケープの書き方を変えると別のキーになり、いくらでも増やせる。そこで 1,024 パスになったら全部捨てて始め直す。今のページは記事と文書とその `.md` 版、`/`、`/docs/`、`/favicon.svg`、`/site.css` で 40 ほどなので、普段は捨てることはない。`BASE_URL` が変わったときも捨てる。
- **本文の再利用**: `new Response(body, ...)` に同じ `Uint8Array` を何度渡しても、本文は毎回同じだった（`wrangler dev` で同じパスを 3 回取って Go 版と同じハッシュ、`make compare` を続けて 3 回）。`Response` は本文のバイト列をコピーする。
- Wasm には手を入れていない。キャッシュは JS の側だけにある。

### 数字

| | キャッシュなし | キャッシュに当たったとき |
| --- | --- | --- |
| `/`（Node） | 17.1〜17.6 µs | 4.9〜5.0 µs |
| いちばん大きいページ（Node） | 347〜351 µs | 33 µs |

- キャッシュに当たったときの 33 µs は、ほぼ Node が 53,784 B の本文の `Response` を作って読む時間。最初のリクエストは今までと同じ時間がかかる。
- 本番で、どれくらいの割合のリクエストが同じ isolate に当たるかは分からない（isolate はデータセンターごとにあり、いつ捨てられるかも決まっていない）。本番での CPU 時間の変化も測っていない。
- `make dev` とローカルの Go 版を、44 パス + 変なエスケープの 14 パス + `/posts/hell%6F` と `/site.css?v=other` の 60 パスで、続けて 3 回比べた。2 回目と 3 回目はキャッシュから返る。どの回も、一致しないのは案 H の節の `/%FF//` だけだった。デプロイした `blog` でも同じく 3 回比べ、一致しないのは案 H の節の 3 パスだけだった。
- デプロイした版の Total Upload は 276.63 KiB（gzip 後 88.03 KiB。文書がこのメモの分だけ増えた）、Worker Startup Time は 2 ms。

## 次の一歩（一つずつ確かめる）

1. （済み）案 D'（UTF-8 の線形メモリ、export は `serve` と `memory`）と案 G（メソッドを渡す）を `moonbit/worker` と `worker.mjs` に取り込み、`make compare` で Go 版と一致することを確かめる。「取り込み」の節を参照。
2. （済み）案 F（`moon-wasm-opt -Oz`）を `make build` に入れ、サイズと `make compare` を確かめる。「取り込み（案 F、`-Oz`）」の節を参照。
3. （済み）1 と 2 をデプロイし、Total Upload と Worker Startup Time を記録する。
4. 2026-10-21 ごろ以降に、フラグ入りの wrangler で案 E を `wrangler dev` で動かす。動けば、本番でも試してから D' と比べ直す。
5. （済み）案 H（パスのデコード）と案 I（応答のキャッシュ）を試す。I は [Static Assets の TODO](moonbit-static-assets.md) で文章を JS から渡すときにも関わる。線形メモリの形にしておけば、文章をコード単位ずつではなく、UTF-8 のバイト列のまま渡せる。

## spike のコード

### 案 D'

`worker_utf8d/moon.pkg`:

```
import {
  "podhmo/blog/site",
  "moonbitlang/core/encoding/utf8",
}

supported_targets = "+wasm-gc"

options(
  link: {
    "wasm-gc": {
      "exports": [ "serve" ],
      "export-memory-name": "memory",
    },
  },
)
```

MoonBit（`load`、`answer` は、`BASE_URL` が変わったら `Site` を作り直すことと、`render` の結果を `status\nname\tvalue\n...\n\n` と本文に分けることだけをする）:

```moonbit
///|
extern "wasm" fn load8(addr : Int) -> Int =
  #|(func (param i32) (result i32) (i32.load8_u (local.get 0)))

///|
extern "wasm" fn store8(addr : Int, v : Int) =
  #|(func (param i32) (param i32) (i32.store8 (local.get 0) (local.get 1)))

///|
extern "wasm" fn memory_size() -> Int =
  #|(func (result i32) (memory.size))

///|
extern "wasm" fn memory_grow(pages : Int) -> Int =
  #|(func (param i32) (result i32) (memory.grow (local.get 0)))

///|
/// reserve grows the memory to hold at least n bytes.
fn reserve(n : Int) -> Unit {
  let more = (n + 65535) / 65536 - memory_size()
  if more > 0 {
    ignore(memory_grow(more))
  }
}

///|
/// write8 encodes s in UTF-8 at address at, and returns the end.
fn write8(at : Int, s : String) -> Int {
  reserve(at + s.length() * 3)
  let mut p = at
  let n = s.length()
  let mut i = 0
  while i < n {
    let mut c = s.code_unit_at(i).to_int()
    i += 1
    if c >= 0xD800 && c < 0xDC00 && i < n {
      let d = s.code_unit_at(i).to_int()
      if d >= 0xDC00 && d < 0xE000 {
        c = 0x10000 + ((c - 0xD800) << 10) + (d - 0xDC00)
        i += 1
      }
    }
    if c < 0x80 {
      store8(p, c)
      p += 1
    } else if c < 0x800 {
      store8(p, 0xC0 | (c >> 6))
      store8(p + 1, 0x80 | (c & 0x3F))
      p += 2
    } else if c < 0x10000 {
      store8(p, 0xE0 | (c >> 12))
      store8(p + 1, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 2, 0x80 | (c & 0x3F))
      p += 3
    } else {
      store8(p, 0xF0 | (c >> 18))
      store8(p + 1, 0x80 | ((c >> 12) & 0x3F))
      store8(p + 2, 0x80 | ((c >> 6) & 0x3F))
      store8(p + 3, 0x80 | (c & 0x3F))
      p += 4
    }
  }
  p
}

///|
/// serve reads the request, n UTF-8 bytes at address 0, and writes the
/// response there in UTF-8, returning its length in bytes.
pub fn serve(n : Int) -> Int {
  let req = @utf8.decode(Bytes::makei(n, i => load8(i).to_byte())) catch {
    _ => ""
  }
  let (head, body) = answer(req)
  write8(write8(0, head), body)
}
```

`worker.mjs`:

```js
import wasm from "./build/app.wasm";

const { memory, serve } = new WebAssembly.Instance(wasm).exports;
const encoder = new TextEncoder();
const decoder = new TextDecoder();

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    let path;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    const req = `${env.BASE_URL ?? ""}\n${request.method}\n${url.search.slice(1)}\n${path}`;
    const more = Math.ceil((req.length * 3) / 65536) - memory.buffer.byteLength / 65536;
    if (more > 0) memory.grow(more);
    const { written } = encoder.encodeInto(req, new Uint8Array(memory.buffer));
    // serve may grow the memory, which detaches the old memory.buffer.
    const n = serve(written);
    const out = new Uint8Array(memory.buffer, 0, n);
    let end = out.indexOf(10);
    while (out[end + 1] !== 10) end = out.indexOf(10, end + 1);
    const [status, ...headers] = decoder.decode(out.subarray(0, end)).split("\n");
    return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
  },
};
```

### 案 E

`moon.pkg` の link 設定:

```
options(
  link: {
    "wasm-gc": {
      "exports": [ "serve" ],
      "use-js-builtin-string": true,
      "imported-string-constants": "wasm:js/string-constants",
    },
  },
)
```

MoonBit の入り口は `pub fn serve(base : String, verb : String, path : String, query : String) -> String` で、`status\nname\tvalue\n...\n\n` と本文をつないだ文字列を返す。`wrangler.jsonc` に `"compatibility_flags": ["wasm_esm_integration_builtins"]` を足し、`worker.mjs` は次のとおり。

```js
import wasm from "./build/app.wasm";

const { serve } = new WebAssembly.Instance(wasm).exports;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    let path;
    try {
      path = decodeURIComponent(url.pathname);
    } catch {
      return new Response("Bad request: malformed path\n", { status: 400 });
    }
    const out = serve(env.BASE_URL ?? "", request.method, path, url.search.slice(1));
    const end = out.indexOf("\n\n");
    const [status, ...headers] = out.slice(0, end).split("\n");
    return new Response(out.slice(end + 2), { status: +status, headers: headers.map((h) => h.split("\t")) });
  },
};
```
