---
title: JS と wasm のあいだを線形メモリで渡す
description: MoonBit の wasm と Worker のあいだの受け渡しを、コード単位ごとの呼び出しから線形メモリの UTF-8 に変えて、いちばん大きいページの処理時間がほぼ半分になった話。
---
[前の記事](./2026-10-18-moonbit.md)で、MoonBit の wasm と JS のあいだでは、文字列を UTF-16 のコード単位ごとに 1 つずつ受け渡していると書いた。
遅そうに見えるが、往復の時間ではほとんど差が出ない、とも書いた。
測り直すと、そうでもなかった。

## どこに時間がかかっていたか

Node で、いちばん大きいページ（約 54 KB）を 1 回返すのに約 740 µs かかっていた。
このうち、wasm の中でページを組み立てる時間は約 345 µs で、残りの約 390 µs が受け渡しだった。
1 文字ごとに JS と wasm を行き来するので、半分以上が境界をまたぐ呼び出しに消えていた。

## 試した方法

| 方法 | いちばん大きいページ |
| --- | --- |
| コード単位を 1 つずつ（前の形） | 727〜766 µs |
| 1 回の呼び出しで 8 コード単位ずつ | 643〜651 µs |
| 線形メモリに UTF-16 で書く | 445〜503 µs |
| 線形メモリに UTF-8 で書く | 393〜435 µs |
| js-string builtins（Node でだけ） | 543 µs |

線形メモリに UTF-8 で書く形にした。

- MoonBit の wasm-gc の出力にも、使われていない線形メモリが 1 ページある。それを export し、inline wasm の `i32.load8_u` / `i32.store8` で読み書きする。
- JS は要求を `TextEncoder.encodeInto` でメモリの先頭に書き、`serve(長さ)` を呼ぶ。wasm は応答（ステータス、ヘッダー、本文）を同じ場所に上書きし、長さを返す。
- 本文は `Uint8Array` のまま `Response` に渡すので、JS の文字列を作らない。
- export は `serve` と `memory` の 2 つ、import は 0 になった（前は export 4 つ、import 4 つ）。

1 つ引っかかった。`new Uint8Array(memory.buffer, 0, serve(n))` と書くと、`serve` より先に `memory.buffer` を読む。
`serve` の中でメモリが増えると、その `ArrayBuffer` は detach されていて `TypeError` になる。
いちばん大きいページでも最初の 64 KiB に収まっていたので、しばらく気づかなかった。

js-string builtins は、MoonBit の文字列がそのまま JS の文字列になるので、いちばん素直に書ける。
ただし Workers は import した wasm をこのオプションなしでコンパイルするので、今は使えない。
workerd には、これを有効にする互換性フラグ `wasm_esm_integration_builtins` が入ったばかりで、試せるのはもう少し先になる。

## ついでに直したこと

- **`wasm-opt -Oz`**: moon に同梱の `moon-wasm-opt` で、依存を増やさずにかけられた。wasm は 6.3% 小さくなった。
- **メソッド**: 前の Worker は POST にも同じページを 200 で返していた。メソッドを wasm に渡し、Go 版と同じく GET と HEAD 以外は 404 にした。
- **パスのデコード**: JS の `decodeURIComponent` をやめ、wasm でデコードするようにした。`/%FF` のような、UTF-8 でないパスにも Go 版と同じ 404 を返す。デプロイした Worker では、`/%zz` のような壊れたエスケープは、Cloudflare の前段が Worker に届く前に 400 で止める。
- **キャッシュ**: 記事は wasm に埋め込んであって変わらないので、GET と HEAD への 200 の応答を、isolate の中でパスごとに持つことにした。2 回目からは wasm を呼ばない。

## 結果

| | 前 | 後 |
| --- | --- | --- |
| いちばん大きいページ（Node） | 約 676 µs | 約 358 µs（キャッシュに当たると約 33 µs） |
| `worker.mjs` | 65 行 | 29 行（キャッシュを入れて 53 行） |
| 起動時間 | 2 ms | 2〜3 ms |

起動時間は ms 単位でしか出ないので、差は見えなかった。
試した方法と数字は、[探索メモ](../docs/sketch/ja/moonbit-workers-adapter.md)にまとめてある。
