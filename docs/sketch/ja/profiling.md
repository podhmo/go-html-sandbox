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

## 追記（実験）: `Inline` をインターフェースから構造体にする

上の節で残した「`Inlines` のアロケートは `Inline` インターフェースへの箱詰め」を、API を変えて取る実験。MoonBit との対応は気にしない方針で、Go だけを見る。

- `Inline` を種別つきの構造体にすると、箱詰めが消える。まず素直に 4 つのフィールド（`Kind`、`Text`、`Children`、`URL`）を持つ構造体にしたところ、1 つ 64 バイトになり、`append` の伸長で写す量が増えて**遅く**なった（`BenchmarkInlines` で 98.5 µs → 152 µs、384 KB/op）。箱詰めのアロケートは消えても、大きい値を伸長のたびに写すほうが高くついた。
- リンクはまれなので、リンクの子と URL はポインタの先（`*linkData`）に置き、`Inline` を 32 バイトに収めた。子と URL は `Children()` と `URL()` で取る。
- あわせて、`Inlines` の結果のスライスを、`` ` `` と `[` の数から見積もって先に確保する。これだけでも効く（インターフェースのままでも 98.5 → 77.3 µs）。

| | 前（PR #43） | インターフェース + 先確保 | 64 バイトの構造体 + 先確保 | 32 バイトの構造体 + 先確保 |
| --- | --- | --- | --- | --- |
| `BenchmarkInlines` | 98.5 µs/op、128,624 B/op、1,735 allocs/op | 77.3 µs/op、56,624 B/op、1,725 allocs/op | 74.2 µs/op、115,200 B/op、6 allocs/op | 58.2 µs/op、57,920 B/op、10 allocs/op |

- アロケートは 1,735 から 10 に減った。時間は 41% 減り、バイト数はほぼ同じ。箱詰めを消すより、値を小さく保つこととスライスを先に確保することのほうが効いた。
- API は変わる。`Text`・`Code`・`Link` は型から関数になり、リンクの子と URL は `Children()` と `URL()` で取る。呼んでいるのは `site` だけだったので、そこだけ直せば済んだ。
- 出力は変えていない（実サーバーの 11 ページで diff なし）。
- `BenchmarkParse` の残りは `scan` の行ごとの蓄積（`strings.Join` とスライス）で、こちらは触っていない。

## 追記（実験）: `el` のライターを `io.Writer` から `io.StringWriter` にする

`el` の CPU プロファイルでは `io.WriteString` が 30% を占めていた。これはインラインされない関数で、呼ぶたびに `w.(io.StringWriter)` の型アサーションをする。描画は短い断片を数多く書くので、この 1 回ぶんが積み上がる。そこで、`Render` と `Renderer` の受け取るライターを `io.Writer` から `io.StringWriter`（`el.Writer` という別名。`bytes.Buffer` も `strings.Builder` も `bufio.Writer` もこれを満たす）に変え、`io.WriteString(w, s)` を `w.WriteString(s)` にした。

- ついでに、`BoolAttr` が `" "+string(n)` を連結していた（値なし属性ごとに文字列を 1 つ作る）。`" "` と本体を分けて書くようにした。
- `voidElements` と `blockElements` の map 引き（プロファイルで 16%）を `switch` にしたところ、**遅く**なった（`BenchmarkRenderHTML` で 52.0 µs → 55.9 µs）。短い文字列を何度も比べる `switch` より、AES ハッシュの効く map のほうが速い。map に戻した。
- 呼び出し側は `pkg/picoel` の別名に `Writer` を足し、`render_test.go` の `failWriter` を `WriteString` にするだけで済んだ。`os.File` のように `io.StringWriter` でないものへ書くには `bufio.Writer` などで包む必要がある（API の変更点）。

| | 前（PR #43 / B） | 後 |
| --- | --- | --- |
| `BenchmarkRenderHTML` | 64.2 µs/op、0 B/op、0 allocs/op | 51.3 µs/op、0 B/op、0 allocs/op |

- 20% 減った。アロケートは前から 0 のまま。
- 残る上位は `writeEscaped` の走査（30%）と、`bytes.Buffer` への写し（`memmove`、11%）。`writeEscaped` は 5 文字を 1 バイトずつ見ていて、そこは触っていない。
- 出力は変えていない（実サーバーの 11 ページで diff なし、`make check` が通る）。`make compare` は MoonBit の道具立てが要るのでこの環境では回していないが、Go 側の出力は同じ。

## 次にやること

- MoonBit 版の `pkg/el` と `pkg/tinymarkdown` を同じ目で見る（`moon bench`。関数レベルの内訳が要れば js ビルドを Node の `--cpu-prof` で）。
- `Inlines` のアロケートは上の追記で減らした（`Inline` を構造体にする API 変更）。残るのは `Parse` の `scan` が行ごとに蓄積しているところ。
- `el` の残りは `writeEscaped` の 1 バイトずつの走査。`io.WriteString` は上の追記で外した。
