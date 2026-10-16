# 探索メモ: MoonBit の Workers 用アダプターを汎用化する

TODO.md の「MoonBit の Workers 用アダプターを汎用化する」（[issue #33](https://github.com/podhmo/html-sandbox/issues/33)）の記録（2026-10-16）。
[PR #31](https://github.com/podhmo/html-sandbox/pull/31) の[探索メモ](moonbit-workers-adapter.md)で磨いたアダプターは、ブログ専用だった。要求として渡すのは `BASE_URL`、メソッド、クエリー、パスだけで、POST の本文もヘッダーも Wasm に届かない。
これを、どの Worker でも使えるライブラリの形に切り出せるかを確かめた。Go 版や net/http に寄せることは目的にせず、ルーティングと要求・応答の扱いで同じような機能が使えることを目指した。

## 結論

- **切り出せる。** 形は次の 3 つに分かれる。
  1. `http`（`moonbit/http`）: 要求、応答、ヘッダー、クエリー、フォーム、ルーター。ホストに依存しない純粋な MoonBit で、native でもテストできる。
  2. `http/wasm`（`moonbit/http/wasm`）: 線形メモリを通した受け渡し（wire 形式、`handle`）。wasm-gc 専用。
  3. `http/wasm/adapter.mjs`: JS の側。`wasmApp(module, { maxBodySize })` が `fetch` を返す（94 行）。
- アプリの側に要るのは、`pub fn serve(n : Int) -> Int { @wasm.handle(n, handler) }` の 1 関数と、`moon.pkg` の link 設定（`"exports": ["serve"]`、`"export-memory-name": "memory"`）だけ。
- **POST、クエリー、本文（テキスト、JSON、バイト列）、フォーム（urlencoded と multipart）、パスの wildcard、メソッドごとのルート、405、複数の `Set-Cookie`、バイナリの応答、Worker の変数**が、Node と `wrangler dev` の両方で使えた（例: `moonbit/examples/echo`）。
- **ブログもこのライブラリの上に載せ替えた。** `worker` は要求を `Site::handle` に渡すだけになり、`Site` のルーティングは `Router` になった。`make compare` は前と同じく `/%FF//` 以外が Go 版と一致し、Wasm は約 5 KB（1.8%）増え、速さは変わらない。
- 汎用化で新しく分かった制約: **いまの `serve` は同期なので、ハンドラーから KV、R2、D1、`fetch` などの非同期の I/O を呼べない。** ただし **JSPI（JavaScript Promise Integration）を使えば、Wasm から JS の `fetch` を同期の関数のように呼んで待てることを、Node と `wrangler dev` で確かめた**（「JSPI で JS の fetch を待つ」の節）。本文はすべて一度に受け渡すので、ストリーミングはできない。

## ライブラリの形

### `http`（ホストに依存しない部分）

`moon info` の出力（`moonbit/http/pkg.generated.mbti`）から、主なものを抜き出す。

```moonbit
pub struct Request {
  verb : String          // メソッド。`method` は予約語なので使えない
  url : String           // ホストから受け取ったまま
  host : String
  raw_path : String      // エスケープしたまま
  path : String          // デコードした後
  raw_query : String
  headers : Headers
  body : Bytes
  env : Map[String, String]     // Worker の変数など、要求の外から渡るもの
  params : Map[String, String]  // Router が埋める wildcard の値
}
pub fn Request::Request(verb~ : String, url~ : String, headers? : Headers, body? : Bytes, env? : Map[String, String]) -> Self raise BadRequest
pub fn Request::query(Self) -> Values
pub fn Request::param(Self, String) -> String
pub fn Request::text(Self) -> String
pub fn Request::json(Self) -> Json raise BadRequest
pub fn Request::form(Self) -> Form raise BadRequest

pub(all) enum Body { Text(String); Binary(Bytes) }
pub struct Response { status : Int; headers : Headers; body : Body }
pub fn Response::Response / text / html / json / typed / redirect
pub fn Response::header(Self, String, value~ : String) -> Unit   // その場で書き換える。`..header(..)` でつなぐ

pub struct Router { ... }
pub fn Router::Router(decoded_path? : Bool, not_found? : Handler, method_not_allowed? : (Request, Array[String]) -> Response) -> Self
pub fn Router::handle(Self, String, Handler) -> Unit
pub fn Router::serve(Self, Request) -> Response
```

- `Headers` は名前と値の組の配列で、名前は大文字小文字を区別せずに引く。同じ名前を何度も持てる（`Set-Cookie`）。
- `Values` はクエリーや urlencoded のフォームの組の配列。`get` は最初の値、`get_all` はすべての値。
- `Form` は、ファイルでない欄の `Values` と、`File`（欄の名前、ファイル名、Content-Type、`Bytes`）の配列。
- エラーは `BadRequest` 1 つにまとめた。要求の解釈に失敗したら投げ、`http/wasm` は 400 で返す。

### ルーター

Go 1.22 の `ServeMux` のパターンをまねた。`"[METHOD ]/path"` で、セグメントはリテラル、`{name}`（1 セグメント、空は不可）、`{name...}`（残り全部）、`{$}`（そこで終わる）。`/` で終わるパターンは、その下のすべてのパスに当たる。

- GET のパターンは HEAD にも当たる。
- パスに当たるパターンが、ほかのメソッドのものしかなければ 405 と `Allow` を返す。何にも当たらなければ 404。どちらも `Router::Router` の引数で差し替えられる。
- **優先順位**: より狭いパターンが勝つ。セグメントごとに、リテラル > `{$}` > `{name}` > `{name...}` > `/` で終わる部分木の順に比べ、同じならメソッドを指定したほうが勝つ。登録の順番は、同じ強さのときだけ効く。Go は重なりがあいまいなパターンを登録すると panic するが、こちらは登録の順で決める。
- **パスの分け方**: 既定では、エスケープしたままのパスを `/` で分けてから、セグメントごとにデコードする（Go 1.22 と同じ）。`/posts/a%2Fb` の `{slug}` は `a/b` になる。`decoded_path=true` にすると、デコードした後のパスを `/` で分ける。ブログは後者を使う（下の「ブログの載せ替え」）。
- 足りないもの: `{slug}.md` のような、wildcard の後ろに続く接尾辞のパターンはない（ブログはハンドラーで接尾辞を見ている）。ホスト名でのルーティング、`/a` から `/a/` への自動のリダイレクト、ミドルウェアの仕組みもない。ミドルウェアは、ハンドラーを包む関数を書けば足りる（ブログのメソッドの確認とリダイレクトがそう）。

### `http/wasm`（受け渡し）

PR #31 の案 D'（線形メモリに UTF-8 でまとめて書く）を、要求の全体を運べるように広げた。

要求（JS が番地 0 から書く）:

```
method \n url \n (name \t value \n)* \n (name \t value \n)* \n body
```

メソッド、URL、ヘッダー、空行、env、空行、本文（バイト列のまま）。

応答（Wasm が上に書く。`serve` は長さを返す）:

```
status \n (name \t value \n)* \n body
```

- 本文の前までは UTF-8 のテキストで、名前と値に改行は入らない（`Headers` が改行を受け付けないため）。値にはタブが入りうるので、名前と値は**最初の**タブで分ける。PR #31 の `worker.mjs` は `split("\t")` で全部のタブで分けていたので、タブを含む値が壊れる可能性があった（ブログの応答のヘッダーには入らない）。
- env は、文字列の値で改行を含まないものだけを渡す（`vars` の JSON の値やバインディングのオブジェクトは渡さない）。PR #31 では `BASE_URL` だけを決め打ちで渡していた。
- 応答の本文は `Body::Text` なら UTF-8 に書き、`Body::Binary` ならバイトをそのまま写す。
- **本文の上限**: `wasmApp` の `maxBodySize`（既定は 1 MiB）を超える本文には、Wasm を呼ばずに 413 を返す。本文はストリームのまま上限まで読み、超えたらそこで捨てる（`Content-Length` のない要求にも効く）。Wasm の線形メモリは一度増えると減らないので、上限がないと、大きな POST を 1 つ送るだけで isolate のメモリ（128 MB）を食いつぶしうる。Workers は要求の本文をプランに応じて 100 MB 以上まで通す。PR #31 のアダプターは本文を読まなかったので、この危険は汎用にして初めて生じた。
- JS の側では、101、103、204、205、304 の応答は本文を `null` にする。`new Response(body, { status: 204 })` は本文があると `TypeError` になる。ブログでは起きなかったが、汎用にすると要る。

### アプリから見た形

```moonbit
let app : @http.Router = {
  let r = @http.Router()
  r.handle("GET /hello/{name}", req => @http.Response::text(200, "hello, \{req.param("name")}\n"))
  r.handle("POST /form", req => { ... req.form() ... })
  r
}

pub fn serve(n : Int) -> Int {
  @wasm.handle(n, req => app.serve(req))
}
```

```js
import wasm from "../../_build/wasm-gc/release/build/examples/echo/echo.wasm";
import { wasmApp } from "../../http/wasm/adapter.mjs";
export default wasmApp(wasm);
```

`wasmApp` は `fetch` のほかに、応答を部品（`{ status, headers, body }`）で返す `call` も返す。ブログの `worker.mjs` は `call` の結果をキャッシュし、`toResponse` で毎回 `Response` を作る（PR #31 の案 I をそのまま残した）。
ブログは本文を読まない（GET と HEAD 以外は 404）ので、`worker.mjs` は本文のない `Request` を作り直して `call` に渡す。413 にせず、Go 版と同じ 404 を返すため。50,000,000 B の POST にも、Go 版と同じ 404 を返した（`wrangler dev`）。
`new Request(request, { body: null })` では本文が消えない（Node で確かめた。`init.body` が `null` でも、元の要求の本文が使われる）。`new Request(request.url, request)` も、`request` を init として読むので本文が付いてくる。`new Request(url, { method, headers })` と書く。

## 試したこと

### 1. ライブラリへの切り出し

`worker/memory.mbt` を `http/wasm` に移し、要求の解釈を wire 形式に置き換えた。ブログの `worker` は、`req.env` の `BASE_URL` で `Site` を読み、`Site::render(req.path, query=req.raw_query, verb=req.verb)` の結果を `@http.Response` に直すだけになった。

### 2. 例（`moonbit/examples/echo`）

ライブラリの機能を一通り使う例を作った。`make test` は Node で、`make dev-echo` は `wrangler dev` で動かす（デプロイはしない）。

| ルート | 確かめたこと |
| --- | --- |
| `GET /{$}` | フォームのある HTML |
| `GET /hello/{name}` | wildcard（`%E6%97%A5` は `日`）、クエリー（`greeting=hey+you` の `+` は空白） |
| `/echo`（メソッドなし） | メソッド、ホスト、パス、同じ名前が 2 回あるクエリー、Content-Type、本文（改行を含む日本語） |
| `POST /json` | JSON の本文。壊れた JSON は 400 |
| `POST /form` | urlencoded と multipart。multipart は 100,000 B のランダムなバイナリのファイル（curl の `-F`）と、Node の `FormData` + `Blob` |
| `PUT` / `DELETE /items/{id}` | メソッドごとのルート。`DELETE` の 204 は本文なし。`GET` は 405 で `Allow: PUT, DELETE` |
| `GET /files/{path...}` | 残り全部の wildcard |
| `GET /redirect` | 303 と `Location` |
| `GET /bytes` | 0〜255 のバイト列の応答（SHA-1 が一致） |
| `GET /cookie` | 要求の `Cookie` と、2 つの `Set-Cookie` |
| `GET /env` | `wrangler.jsonc` の `vars` |

ほかに、200,000 B の本文（線形メモリの最初の 1 ページ、64 KiB を超える）、壊れたエスケープのパス（`/%zz` は 400）、HEAD（GET のルートに当たり、本文なし）も確かめた。

### 3. ブログの載せ替え

`Site::render` の手書きの分岐を `Router` にした（`Site::handle`）。

- メソッドの確認（GET と HEAD 以外は 404）と、正規化したパスへのリダイレクトは、Go 版の `route` と同じくルーターの前に置いた。どちらもルーターの仕組みでは書けない（メソッドが違えば 405 ではなく 404 にしたい、すべてのパスに先にかけたい）ので、ハンドラーを包む形になる。
- **`decoded_path` が要った。** Go 版は `r.URL.Path`（デコードした後）で分岐するので、`/docs%2F` は `/docs/` の一覧になる。既定の分け方（Go 1.22 の ServeMux と同じ）では `docs/` という 1 つのセグメントになって 404 になり、`make compare` で一致しなかった。ブログは手書きの分岐を移植したもので、ServeMux とは振る舞いが違う、というのが理由。
- `site` の `Response` と、パスのデコード（`unescape`、`unescape_path`）は消し、`http` のものを使うようにした。`Site::render` はテストのために残し、パスとクエリーから `@http.Request` を作って `handle` を呼ぶ。
- ルーターは最初の要求で作り、`Site` に持たせる。

## 計測

### Go 版との比較

`make dev` とローカルの Go 版（`-base-url https://blog.podhmo.workers.dev`）を、55 パスで比べた。`/` と `/docs/` からたどれる記事と文書とその `.md` 版、`/docs`、`/docs?x=1`、`//posts/../`、`/_livereload.js`、存在しないパス、`/favicon.svg`、`/site.css`（`?v=other` 付きも）、PR #31 の変なエスケープの 14 パス、`/posts/hell%6F`。

| | 一致しないパス |
| --- | --- |
| 1（切り出し）の後 | `/%FF//` だけ（3 回続けて） |
| 3（載せ替え）の後 | `/%FF//` だけ（2 回続けて） |

- `/%FF//` は PR #31 の案 H の節にある既知の違い。
- POST の `/posts/hello`、`/docs`、`/` は、どちらも 404 で本文が一致した。
- 最初に比べたとき、`/docs/TODO` などが一致しなかった。Go 版の `repodocs` は `go generate` でコピーした文書を埋め込むので、`TODO.md` を書き換えた後に `go generate ./examples/blog/repodocs` を忘れていた。アダプターとは関係ない。
- 本文の上限を入れた版を `make deploy` で `blog` にデプロイし（Total Upload 310.05 KiB、gzip 後 98.60 KiB、Worker Startup Time 2 ms）、同じ 55 パスで比べた。一致しないのは PR #31 の案 H の節と同じ `/%FF//`、`/%zz`、`/a%00b` の 3 つだった。50,000,000 B の POST にも、Go 版と同じ 404 を返した。

### サイズ

同じ文書を埋め込んだビルドで比べた（`-Oz` の後）。

| | Wasm | gzip -9 |
| --- | --- | --- |
| PR #31 のアダプター | 285,293 B | 89,616 B |
| 1. ライブラリに切り出した後 | 287,329 B（+2,036 B） | 90,433 B |
| 3. ブログを `Router` に載せ替えた後 | 290,295 B（+5,002 B） | 91,956 B |
| 例の `echo.wasm`（文書を埋め込まない） | 92,519 B | 44,106 B |

- 切り出しで増えたのは、ヘッダーと env の解釈と `Request` の組み立て。`Router` を使うと、さらに約 3 KB 増える。
- 埋め込んだ文章がない `echo.wasm` でも 92 KB ある。中身（JSON の解析と文字列化、`Map`、ルーター）の内訳は見ていない。

### 処理時間（Node）

PR #31 と同じ測り方（`fetch` に `Request` を渡して本文を読み終えるまで、1,000 回 × 5 回の中央値）。キャッシュは使わない。`user-agent` と `accept` のヘッダーを付けた。load average は 4〜6。

| | `/` | いちばん大きいページ（`/docs/sketch/ja/moonbit-modernize`） |
| --- | --- | --- |
| PR #31 のアダプター | 16.2〜18.5 µs | 382〜401 µs |
| 1. 切り出した後 | 17.8〜22.3 µs | 391〜402 µs |
| 3. `Router` に載せ替えた後 | 18.1〜18.6 µs | 389〜407 µs |

- 差はばらつきの範囲。ヘッダーを渡すぶんの増え方は、`/` で 1 µs 前後。
- 本文をすべて写すコストは、本文の 1 バイトあたり約 1.4 ns（1,000,000 B の本文で、本文を読まない 405 の応答が約 1.4 ms）。
- ただし、本文を文字列にして JSON で返す `echo` のルートは、1 バイトあたり約 30 ns かかった（1,000,000 B で約 33 ms）。`decode_lossy`、`Json::stringify`、コード単位ごとの書き戻しのどれが重いのかは分けて測っていない。ブログのフォームくらいの大きさ（数 KB）なら数十 µs で済む。
- 典型的なブラウザーのヘッダー（9 個、約 700 B）を付けると、`echo` の `GET /hello/x` は 8.5 µs から 15.5 µs になる。ヘッダーは 1 つずつ `Headers` に積むので、本文より 1 バイトあたりが重い。

## 分かったこと

- **MoonBit の `Option` の `ToJson` は、`None` を `[]`、`Some(x)` を `[x]` にする。** `Json(req.headers.get("content-type"))` は `["text/plain"]` になり、テストで気づいた。`null` にしたければ自分で `match` する。
- **`method` は予約語**（PR #31 と同じ）。`Request` のフィールドも `verb` にした。
- `Ref` は、`site` パッケージに同じ名前の型（リンクの参照）があるので、`Ref[T]` と書くと `site` の `Ref` になってエラーになった。`Site` の遅延初期化は `mut` のフィールドにした。
- `typealias` の書き方は `pub type Handler = (Request) -> Response` だった（`pub typealias ... as ...` は構文エラー）。
- 関数を値に持つ `pub struct` のフィールドを `mut` にすると、パッケージの中で書き換えないので `unused_mut` の警告（このリポジトリではエラー扱い）になる。差し替えは `Router::Router` の省略可能な引数で受けることにした。
- `match` の腕にそのまま `guard` は書けない（`Using guard statement in the action part of a matching case directly is not allowed`）。`if !(... is ...) { return None }` にした。

## ライブラリとして出すときに考えること

- **非同期の I/O。** いまの `serve` は同期で、ハンドラーは要求を受けて応答を返すだけ。KV、R2、D1、Static Assets、外への `fetch` を使うには、(a) Wasm が「この I/O をして」という応答を返し、JS が実行して結果を付けて呼び直す、(b) JSPI で Wasm から Promise を待つ、のどちらかが要る。(a) は wire 形式を広げれば今の形のまま書ける。(b) は spike で動いた（次の節）。[Static Assets の TODO](moonbit-static-assets.md) で文章を Wasm の外に出すときも、同じ問題になる。
- **ストリーミング。** 要求も応答も、全部を線形メモリに置く。大きなアップロードやストリーミングの応答（SSE）はできない。ブログの Go 版の live reload（SSE）は、Worker 版では元からない。
- **線形メモリ。** moon は wasm-gc でも 1 ページの線形メモリを出し、使っていない、という前提に乗っている（PR #31 と同じ）。将来 moon がこのメモリを使い始めたら壊れる。メモリは一度増えたら減らない。
- **配り方。** MoonBit のパッケージ（`http`、`http/wasm`）と JS のファイル（`adapter.mjs`）を一緒に配る必要がある。mooncakes.io に JS のファイルを含めて出せるか、wrangler からどう参照させるかは調べていない。いまは同じリポジトリの相対パスで `import` している（wrangler の esbuild がまとめる）。
- **`moon.pkg` の link 設定は、アプリの側に書くしかない。** export する関数はアプリのパッケージにあり、ハンドラーもアプリが渡すので、`serve` の 1 関数はアプリが書く。
- **js-string builtins（PR #31 の案 E）にした場合。** `wasm_esm_integration_builtins` が使えるようになっても、本文がバイト列のまま渡せる線形メモリの形は残す価値がある（バイナリの本文を JS の文字列にすると、壊れるか遅い）。

## JSPI で JS の fetch を待つ（spike）

「Wasm の側から `JS.global.fetch` のように JS の `fetch` を呼べないか」を試した。
呼ぶこと自体は import でできる。問題は、`fetch` が Promise を返し、Wasm のコードは同期なので待てないこと。
JSPI はこれを埋める仕組みで、JS の async 関数を `new WebAssembly.Suspending(f)` で包んで import に渡し、export を `WebAssembly.promising(serve)` で包む。
Wasm がその import を呼ぶと、Wasm のスタックごと止まり、Promise が解決したら続きから動く。Wasm から見ると、ただの同期の関数呼び出しになる。

- **どこで使えるか**: Node 24.21.0 と、wrangler 4.148.0 の workerd（1.20261006.1）の両方で、`WebAssembly.Suspending` と `WebAssembly.promising` が、フラグなしで関数として存在した。
- **MoonBit の側**: 何も特別なことは要らない。`fn host_fetch(n : Int) -> Int = "host" "fetch"` という普通の import 宣言で、wasm-gc のまま動いた。止まっているあいだも、GC の参照を持ったままのスタックが保たれる。
- **確かめたこと**: spike（[`moonbit/experiments/wasm-fetch`](../../../moonbit/experiments/README.md)。`make try`、`make concurrent`、`make dev`）で、`GET /proxy?url=https://example.com/` が上流の 200 と本文を返した。1 つの要求の中で 2 回続けて `fetch` しても動いた。Node でも `wrangler dev` でも同じ。
- **同時に来た要求**: Wasm が 1 つの要求で止まっているあいだに、次の要求が `serve` に入ってくる。応答の長さが違う 3 つの要求（Node では上流が 300 ms と 50 ms で返す、`wrangler dev` では example.com / .org / .net）を同時に送り、どれも自分の応答を受け取った。

ただし、線形メモリの番地 0 を共有する今の受け渡しは、そのままでは同時の要求で壊れる。spike では次のようにした。

1. 要求は、`serve` を呼んだその場で（最初に止まる前に）Wasm が読み終える。
2. `fetch` の結果は、止まる import（`host.fetch`）では JS の側に番号札を付けて取っておくだけにし、Wasm がその番号札で止まらない import（`host.take(ticket)`）を呼んだときに番地 0 に写す。止まる import が値を返してから Wasm が動き出すまでのあいだに、ほかの要求の JS が走りうるため。最初の版は結果を 1 つの変数に取っておいていたので、2 つの `fetch` がほぼ同時に解決すると、別の要求の結果を取りうる形だった（spike をリポジトリに移すときに気づいて直した。`make concurrent` は、同時に解決する 2 つの上流を含めて、どの要求も自分の結果を受け取ることを確かめる）。
3. 応答も同じ理由で、`serve` の戻り値ではなく、止まらない import（`host.done(id, n)`）で、その場で JS に写させる。`serve` には要求ごとの id を渡す。

ライブラリにするなら、`@wasm.handle` とアダプターをこの形（`serve(id, n)`、`take(ticket)`、`done`）に変え、`Request` に「ホストの `fetch` を呼ぶ」関数を足せばよさそう。KV や R2 も、同じように import を足せば呼べるはず（試していない）。

- 本番の Workers で JSPI が使えるかは確かめていない（spike の Worker をデプロイしていない）。
- 止まるたびのコスト、止まったスタックのメモリ、例外が JS と Wasm をまたぐときの扱いは見ていない。

## 計測の道具

この節までの計測は [`moonbit/experiments/http-bench`](../../../moonbit/experiments/README.md) に置いた。`make build` が PR #31 の最後のコミット、ライブラリに切り出したコミット、`Router` に載せ替えたコミットのブログを git の worktree でビルドし、`make bench` が「処理時間（Node）」の表を、`make bench-body` が本文の大きさごとの数字を出す。

## 確かめられなかったこと

- 例の `echo` はデプロイしていないので、POST の本文やフォームを本番の Workers で受けたことはない。本番では `cf-*` などのヘッダーが増える。
- multipart の、`Content-Transfer-Encoding` や、欄の名前に RFC 2231 の `filename*=` を使う形は扱っていない。`filename*` は無視され、`filename` がなければファイルでない欄として扱われる。
- 本文の上限は決めていない。Workers の要求の本文の上限（プランによる）と、Wasm の線形メモリの上限（4 GiB）のどちらに先に当たるかは見ていない。

## 次の一歩

1. JSPI の形（spike）をライブラリに取り込み、本番の Workers で動くか確かめる。Static Assets から文章を取る TODO の決めることと、そのままつながる（Wasm が Static Assets の `fetch` を待てれば、文章を先に全部渡さなくてよい）。
2. ライブラリを別の module（`moon.mod`）に分けて、ブログから依存する形にしてみる。
3. 本文の文字列化と JSON 化が 1 バイトあたり 30 ns かかる内訳を分けて測る。
