---
title: MoonBit の Worker 用アダプターをライブラリにする
description: ブログ専用だった MoonBit の wasm と Worker のあいだの受け渡しを、POST、ヘッダー、フォーム、ルーティングまで扱える小さな HTTP ライブラリに切り出した話。
---
[前の記事](./2026-10-19-moonbit-memory.md)の受け渡しは、このブログのためだけのものだった。
wasm に届くのは `BASE_URL`、メソッド、クエリー、パスだけで、POST の本文もヘッダーも届かない。
これを、ほかの Worker でも使える形に切り出せるかを試した。
Go の net/http に寄せることは目指さず、同じようなことができればよい、とした。

## 形

3 つに分かれた。

| 部分 | 中身 |
| --- | --- |
| [`moonbit/http`](../moonbit/README.md) | `Request`、`Response`、`Headers`、クエリーとフォームの解析、`Router`。ホストに依存しないので native でもテストできる |
| `moonbit/http/wasm` | 線形メモリを通した受け渡し。`handle(n, handler)` |
| `moonbit/http/wasm/adapter.mjs` | JS の側。`wasmApp(module)` が `fetch` を返す（約 90 行） |

アプリが書くのは、ルートと、export する 1 関数だけになる。

```moonbit
let app : @http.Router = {
  let r = @http.Router::new()
  r.handle("GET /hello/{name}", req => {
    let greeting = req.query().get("greeting").unwrap_or("hello")
    @http.Response::text(200, "\{greeting}, \{req.param("name")}\n")
  })
  r.handle("POST /form", req => ...req.form()...)
  r
}

pub fn serve(n : Int) -> Int {
  @wasm.handle(n, req => app.serve(req))
}
```

```js
import wasm from "../../../../_build/wasm-gc/release/build/pkg/http/wasm/integration/integration.wasm";
import { wasmApp } from "../adapter.mjs";
export default wasmApp(wasm);
```

要求は、メソッド、URL、ヘッダー、Worker の変数、本文の順に、線形メモリに書く。
本文の前までは改行で区切った UTF-8 のテキストで、本文はバイト列のまま置く。
だからバイナリのアップロードも、バイナリの応答も、そのまま通る。

## ルーター

Go 1.22 の `ServeMux` のパターンをまねた。

- `GET /posts/{slug}`、`/files/{path...}`、`/{$}` のように書く。GET のパターンは HEAD にも当たる。
- パスは合うがメソッドが違うときは 405 と `Allow`、どれにも合わないときは 404。
- より狭いパターンが勝つ。Go はあいまいな重なりを登録すると panic するが、こちらは登録の順で決める。
- `{slug}.md` のような、wildcard の後ろに続く接尾辞は書けない。

試しに、このブログのルーティングもこのルーターに載せ替えた。
1 つだけ食い違った。Go 版のブログはデコードした後のパスで手で分岐しているので、`/docs%2F` は `/docs/` になる。
`ServeMux` と同じく、セグメントに分けてからデコードすると `docs/` という 1 つのセグメントになり、404 になる。
デコードした後のパスで分けるオプション（`decoded_path`）を足して合わせた。

## 確かめたこと

例として、`moonbit/pkg/http/wasm/integration` に、POST、クエリー、テキストと JSON の本文、urlencoded と multipart のフォーム（100 KB のバイナリのファイル）、`PUT` と `DELETE`、405、複数の `Set-Cookie`、バイナリの応答、Worker の変数を使うルートを置いた。
Node と `wrangler dev` の両方で動いた。

このブログは、ライブラリに載せ替えた後も、Go 版と比べて前と同じパスが一致している。
wasm は約 5 KB 大きくなり、速さは変わらなかった。

1 つ、汎用にしたことで増えた危険があった。
前の Worker は POST の本文を読まずに 404 を返していた。
新しいアダプターは本文を wasm のメモリに写すが、wasm のメモリは一度増えると減らない。
大きな POST を送られると、isolate のメモリを食いつぶしうる。
そこで、本文の上限（既定は 1 MiB、超えたら 413）を足し、このブログは本文を wasm に渡さないようにした。

## まだできないこと

- **非同期の I/O。** `serve` は同期なので、ハンドラーから KV や R2、外への `fetch` を呼べない。ライブラリとして使うなら、ここがいちばん大きな壁になる。
  ただ、JSPI（`WebAssembly.Suspending` と `WebAssembly.promising`）を使うと、wasm から JS の `fetch` を普通の関数のように呼んで待てた。Node と `wrangler dev` の両方で、MoonBit の側は普通の import を宣言するだけで動いた。止まっているあいだに次の要求が入ってくるので、線形メモリの受け渡しは少し組み替える必要がある。本番の Workers ではまだ試していない。
- **ストリーミング。** 要求も応答も、まるごとメモリに置く。

詳しくは[探索メモ](../docs/sketch/ja/moonbit-workers-http.md)にまとめてある。
