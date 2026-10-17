# 調査メモ: profiler で `pkg/el` と `pkg/tinymarkdown` のどこが重いか見る

TODO.md の「Go と MoonBit の `pkg/el` と `pkg/tinymarkdown` に profiler をかけて速くする」の調査。まず Go 版だけをやった。対象は `go/pkg/el` と `go/pkg/tinymarkdown` の 2 つで、ブログ全体や Workers の側（Static Assets、JSPI、アダプター）には広げていない。このメモは Go の結果で、MoonBit の結果は後で足す。

## 結論

- 3 つのベンチマークを足した。入力はリポジトリでいちばん大きい Markdown（`docs/sketch/ja/moonbit-modernize.md`、51,123 B。ベンチが実行時に `docs/` と `posts/` から選ぶ）。

  | ベンチ | 何を測るか |
  | --- | --- |
  | `BenchmarkParse` | `tinymarkdown.Parse`（ブロックの解析） |
  | `BenchmarkInlines` | `tinymarkdown.Inlines`（インラインの解析） |
  | `BenchmarkRenderHTML` | `el.HTMLRenderer` で記事 1 ページぶんの木を描画（`bytes.Buffer` を `Reset` して使い回す） |

- pprof で見えたのは、思ったより「確保」だった。`-cpuprofile` と `-memprofile` を取り、`alloc_objects` で見ると、上位はだいたいアロケートの回数だった。直したのは 3 つ。
  1. `tinymarkdown.cells`: セルごとに `strings.Builder` に 1 バイトずつ書いて `String()` していた。区切りの `|` を `strings.IndexByte` で飛ばし、`\|` をほどくのは cell に `\` があるときだけにした（`unescapeCell`）。
  2. `tinymarkdown.inlines`: 1 バイトずつ `switch` で見ていたループと、`emit` クロージャをやめ、次の `` ` `` か `[` まで `strings.IndexByte` で飛ばす。飛ばした先が素のテキストでないことだけを見る。
  3. `el.HTMLRenderer`: `"<"+タグ名+">"`、`" "+属性名+"=\""+値+"\""` を連結して `io.WriteString` していた。連結はタグと属性ごとにアロケートするので、小分けに書く。あわせて `html.EscapeString`（エスケープが要る値ごとにバッファと文字列を 2 つ作る）をやめ、`&` `'` `<` `>` `"` を `html.EscapeString` と同じ置換で書きながら行う `writeEscaped` にした。

- 前後（`go test -run '^$' -bench . -benchmem -count 3 ./pkg/tinymarkdown ./pkg/el`、AMD Ryzen 7 255、go1.27.1）:

  | ベンチ | 前 | 後 |
  | --- | --- | --- |
  | `BenchmarkParse` | 85.4 µs/op、84,080 B/op、1,423 allocs/op | 55.9 µs/op、56,048 B/op、680 allocs/op |
  | `BenchmarkInlines` | 111.3 µs/op、128,624 B/op、1,735 allocs/op | 98.5 µs/op、128,624 B/op、1,735 allocs/op |
  | `BenchmarkRenderHTML` | 96.8 µs/op、44,192 B/op、2,156 allocs/op | 62.1 µs/op、0 B/op、0 allocs/op |

- `Inlines` のアロケートは減っていない。`Text`・`Code`・`Link` を `Inline` インターフェースに入れる箱詰め（と `[]Inline` の伸長）が `alloc_space` の約 9 割を占める。減らすには API を変えることになる（`Inline` を種別つきの構造体にするなど）ので、今回は触っていない。時間だけ 12% 減った。
- 出力は変えていない。`make check`（gofmt、go vet、go test）が通る。

## ベンチの置き場所

- `go/pkg/tinymarkdown/bench_test.go` と `go/pkg/el/bench_test.go`。
- `el` の木は、記事 1 ページの形（段落 200、入れ子のリスト、表）をベンチの中で組む。
- `tinymarkdown` の入力は、`docs/` と `posts/` を歩いていちばん大きい `.md` を選ぶ（パッケージからの相対で `../../../docs`、`../../../posts`）。見つからなければ skip する。実物の文書を使うのは、`Parse` と `Inlines` の重さが入力の形（表、コードスパン、箇条書きの量）で変わるから。記事を 1 本足しても、いちばん大きい文書を選び直す。

## プロファイルの取り方

```sh
cd go
go test -run '^$' -bench . -benchmem \
  -cpuprofile cpu.out -memprofile mem.out ./pkg/tinymarkdown ./pkg/el
go tool pprof -top -nodecount=15 cpu.out
go tool pprof -top -nodecount=15 -sample_index=alloc_objects mem.out
go tool pprof -list 'tinymarkdown.inlines' cpu.out
```

- `alloc_space` より `alloc_objects` のほうが効いた。この 2 つは、大きいバッファより小さいアロケートが数で効いていた。
- `runtime.futex` が上位に出るのは、`b.Loop` と `GOMAXPROCS=16` のせいで、ホットスポットではない。

## 次にやること

- MoonBit 版の `pkg/el` と `pkg/tinymarkdown` を同じ目で見る（`moon bench`。関数レベルの内訳が要れば js ビルドを Node の `--cpu-prof` で）。
- `Inlines` のアロケートを減らすなら、`Inline` の API を見直すところから。
