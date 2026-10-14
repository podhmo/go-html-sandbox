---
title: TinyGo と標準 Go、2 つの wasm ビルド
description: Cloudflare Workers 向けのビルドを TinyGo と標準 Go に分けた話と、実は今は TinyGo なしで動いている話。
---
このブログは、同じ `http.Handler` を Cloudflare Workers でも動かせる。
Workers 用のエントリポイントは別モジュールの `examples/blog/workers` にあり、
[syumai/workers-go](https://github.com/syumai/workers-go) で wasm にして載せている。

## ビルドを 2 つに分けた

[`wrangler.jsonc`](../workers/wrangler.jsonc) には、ビルドの方法が 2 つある。

| コマンド | コンパイラ | wasm のサイズ |
| --- | --- | --- |
| `npx wrangler dev` | TinyGo（`-target wasm -no-debug`） | 約 2.0 MiB |
| `npx wrangler dev --env go` | 標準 Go（`GOOS=js GOARCH=wasm`） | 約 8.2 MiB |

どちらも同じソースからビルドする。
ビルドタグを `tinygo` ではなく `js && wasm` にしてあるので、どちらのコンパイラでも同じファイルが選ばれる。

TinyGo のほうが 4 分の 1 ほど小さいが、そのぶん手間もある。

- TinyGo の `net/http.ServeMux` は Go 1.22 より前の実装のままで、`GET /posts/{slug}` のようなパターンが使えない。そのためルーティングを手書きにした。
- `os.OpenRoot` もないので、`-debug` 用のコードは Workers のビルドから外した。
- この種の差異は `tinygo test ./examples/blog/internal/site` で検出できる。

## 実は TinyGo なしで動いている

デプロイしているのは標準 Go のビルド（`--env go`）のほうで、TinyGo は使っていない。

もともと TinyGo を選ぶ一番の理由はサイズだった。
Workers のサイズ制限は圧縮後で Free プランが 3 MB、Paid プランが 10 MB で、
標準 Go の wasm は gzip しても約 2.3 MB と、Free プランの上限に近かった。

2026-09-04 の [changelog](https://developers.cloudflare.com/changelog/post/2026-09-04-increased-worker-size-limit/) で、
制限は「非圧縮で 64 MiB（全プラン共通）、圧縮後は無制限」に変わった。
8.2 MiB の wasm でも余裕で収まるので、サイズはもう TinyGo を選ぶ決め手にならない。
TinyGo を入れていない環境でも、Go さえあれば `wrangler deploy --env go` でデプロイできる。

なお、この wasm がブラウザに送られることはない。
wasm は Cloudflare のエッジで動き、ブラウザが受け取るのはサーバー側でレンダリングされた HTML だけ。

## それでも TinyGo を残している理由

wasm が小さいほど、エッジで Worker を読み込むときのコンパイルが速いはずで、コールドスタートでは TinyGo が有利になる。
ただし本番での計測はまだしていない。

詳しくは [実験レポート](../../../docs/sketch/ja/blog-tinygo-workers.md) にまとめてある。
