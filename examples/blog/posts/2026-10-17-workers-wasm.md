---
title: TinyGo と標準 Go、2 つの wasm ビルド
description: Cloudflare Workers 向けのビルドを TinyGo と標準 Go に分けた話と、TinyGo を入れずに Docker でビルドしてデプロイしている話。
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

## どちらでもデプロイできる

どちらのビルドも同じ Worker（`blog`）としてデプロイされ、後からデプロイしたほうが動く。
今デプロイしているのは TinyGo のビルドで、アップロードは gzip 後で約 760 KiB、起動時間は 8 ms と表示された。

TinyGo はホストに入れていない。
[`workers/bin/tinygo`](../workers/bin/tinygo) は Docker イメージ `tinygo/tinygo` の中で TinyGo を動かすシェルスクリプトで、
これを `PATH` の先頭に置けば `wrangler.jsonc` のビルドコマンドがそのまま使う。

```sh
cd examples/blog/workers
PATH="$PWD/bin:$PATH" npx wrangler deploy --env=""
```

標準 Go のビルドも残している。
もともと TinyGo を選ぶ一番の理由はサイズだった。
Workers のサイズ制限は圧縮後で Free プランが 3 MB、Paid プランが 10 MB で、
標準 Go の wasm は gzip しても約 2.3 MB と、Free プランの上限に近かった。

2026-09-04 の [changelog](https://developers.cloudflare.com/changelog/post/2026-09-04-increased-worker-size-limit/) で、
制限は「非圧縮で 64 MiB（全プラン共通）、圧縮後は無制限」に変わった。
8.2 MiB の wasm でも余裕で収まるので、Docker も TinyGo もない環境でも、Go さえあれば `wrangler deploy --env go` でデプロイできる。

なお、この wasm がブラウザに送られることはない。
wasm は Cloudflare のエッジで動き、ブラウザが受け取るのはサーバー側でレンダリングされた HTML だけ。

## TinyGo を選ぶ理由

wasm が小さいほど、エッジで Worker を読み込むときのコンパイルが速いはずで、コールドスタートでは TinyGo が有利になる。
ただし、標準 Go のビルドと並べた本番での計測はまだしていない。

詳しくは [実験レポート](../../../docs/sketch/ja/blog-tinygo-workers.md) にまとめてある。
