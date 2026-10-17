# 調査メモ: profiler で `pkg/el` と `pkg/tinymarkdown` のどこが重いか見る（MoonBit 版）

TODO.md の「Go と MoonBit の `pkg/el` と `pkg/tinymarkdown` に profiler をかけて速くする」の MoonBit 版の調査（[目次](profiling.md)、[issue #39](https://github.com/podhmo/html-sandbox/issues/39)）。対象は `moonbit/pkg/el` と `moonbit/pkg/tinymarkdown` の 2 つで、ブログ全体や Workers の側（Static Assets、JSPI、アダプター）には広げていない。Go 版は [`profiling-go.md`](profiling-go.md)。

## 結論

- Go 版と同じ 3 つのベンチマークを足した。入力も Go 版に合わせた。

  | ベンチ | 何を測るか |
  | --- | --- |
  | `parse` | `@tinymarkdown.parse`（ブロックの解析） |
  | `inlines` | `@tinymarkdown.inlines`（インラインの解析） |
  | `render_html` | `@el.render_html` で記事 1 ページぶんの木を描画 |

  - `tinymarkdown` の入力は、`examples/blog/repodocs` が埋め込んだ文書のうちいちばん大きい `docs/sketch/ja/moonbit-modernize.md`（51,123 B）。Go 版が選ぶのと同じファイル。
  - `el` の木は、Go の `benchPage(200)` と同じ形（段落 200、入れ子のリスト、表）をベンチの中で組む。

- 前後（`moon bench pkg/tinymarkdown` と `moon bench pkg/el`、`--target native` と `--target wasm-gc`。AMD Ryzen 7 255、moon 0.1.20261012。±は省いた。同じ機械でも数 % 揺れる）:

  | ベンチ | native 前 | native 後 | wasm-gc 前 | wasm-gc 後 |
  | --- | --- | --- | --- | --- |
  | `parse` | 185.9 µs | 70.0 µs | 299.1 µs | 109.4 µs |
  | `inlines` | 128.5 µs | 86.9 µs | 205.3 µs | 139.7 µs |
  | `render_html` | 108.2 µs | 67.4 µs | 232.5 µs | 191.3 µs |

  - `parse` は native で 62% 減、wasm-gc で 63% 減。`inlines` は 32% / 32% 減。`render_html` は 38% / 18% 減。

- profiler で見えたのは Go 版と同じで「確保」だった。Go 版で効いたところをなぞった。直したのは 3 つ。
  1. `tinymarkdown.cells`: セルごとに `StringBuilder` に 1 文字ずつ書いて `to_string` していた。区切りの `|` を `find` で飛ばし、`\|` をほどくのは `\` があるときだけにした（`unescape_cell`）。
  2. `tinymarkdown.split_inlines`: 1 文字ずつ `switch` で見ていたループと `emit` クロージャをやめ、テキストをその場で push する。
  3. `el`: `"<\{tag}"` や `" \{name}=\"{value}\""` の補間をやめ、タグと属性の部品を分けて書く。合わせて `write_escaped` を、エスケープが要る文字の間をまとめて書く形にした。
- あわせて、MoonBit 版では行とセルを `StringView` のまま引き回すようにした。Go の `strings.TrimSpace` が部分文字列を返すのと同じで、`trim_space` は `StringView` を返し、`para`・`quote`・`table`・`code` は `Array[StringView]` になった。`to_owned` するのは残す行だけ。`indent`・`is_heading`・`parse_heading`・`backquotes`・`is_delimiter` も、文字集合を作る `trim` をやめて自分で数える。
- 出力は変えていない。`moon test` が全部通り、`make check`（moon fmt、moon check、native と wasm-gc、`make ts`、Node の js テストと integration テスト）が通る。Go 版との一致は `make compare`（Go のブログと Worker を起こして比べる）で確かめる作りだが、この環境では回していない。`pkg/tinymarkdown` と `pkg/el` の出力は変えていないので、`make ts` が出す js ビルド（`ts/pkg/tinymarkdown/tinymarkdown.mjs`）の差分は生成物の変化だけ。

## ベンチの置き場所

- `moonbit/pkg/tinymarkdown/bench_test.mbt` と `moonbit/pkg/el/bench_test.mbt`。`moon.pkg` に `"moonbitlang/core/bench"`（と、`tinymarkdown` は `"podhmo/html-sandbox/examples/blog/repodocs"`）を `for "test"` で足した。
- `tinymarkdown` の入力は `repodocs` の埋め込みからいちばん大きいものを選ぶ。実物の文書を使うのは Go 版と同じ理由で、`parse` と `inlines` の重さが入力の形（表、コードスパン、箇条書きの量）で変わるから。
- `el` の木は Go のベンチと同じ形をベンチの中で組む。

## プロファイルの取り方

- ベンチは `moon bench pkg/tinymarkdown --target native`（`--target wasm-gc` も同じ）で回る。`-p` の形は、js 専用のサブパッケージが混じるパッケージで失敗することがあるので、パスの形（`moon bench pkg/el`）を使う。
- MoonBit には `moon test/run --profile` がある（native では perf、macOS では Time Profiler）。native のコアライブラリの直し方は [Optimizing MoonBit Core](https://moonbitlang.com/pearls/optimize-moonbit-core) にまとまっている。ここでは `moon test --profile pkg/el --target native` も試したが、`Samples: 0` で何も取れなかった（テストが速すぎたか、この環境の perf では MoonBit の記号を引けなかった）。レポートの JSON は `_build/native/release/profile/test/<日時>/profile.json` に出る。
- そこで、Go 版の `pprof` の代わりに `perf` を直に使った。この環境の perf は記号を解決しないので、ASLR を切って記録し、葉の命令アドレスを `addr2line` で関数名に写して集計する（集計のスクリプトは作業用で、コミットしていない）。

  ```sh
  cd moonbit
  # 記号を引けるように debug info を残してビルドする。
  moon bench pkg/el --target native --build-only --release --no-strip
  # ASLR を切って記録する（記録先の実行ファイルが常に同じアドレスに載る）。
  setarch "$(uname -m)" -R perf record -F 10000 -g -o el.perf -- moon bench pkg/el --target native
  # 葉の IP を addr2line に渡して関数ごとに合計する。
  perf script -i el.perf -F ip
  ```

  - 実行ファイルは main のバイナリに静的にリンクされる（動的リンクは libc・libm・ld）。PIE のベースは ASLR を切ると `0x555555554000` になり、`addr2line` にはそのぶんを引いたオフセットを渡す。
  - 上位に `elf_add` や `read_function_entry`（libbacktrace）が出るが、これは起動時に debug info を一度読むぶん。1 回の解析の内訳ではないので無視する。

- 上位（native、`parse`、直す前）: `blit_from_string`（9%）、`moonbit_drop_object`（6%）、`malloc`/`free`（合わせて約 11%）、`is_delimiter`（2%）、`split_inlines`（2%）、`scan`（1%）、`find_code_unit_from_string`（1%）。計算より、確保と写しが上位に出る。
- 上位（native、`render_html`、直す前）: 記号を引けない `??`（23%）、`moonbit_make_string`（12%）、`write_escaped`（9%）、`unsafe_blit_from_string`（8%）、`write_string`（3%）、`write_char`（2%）、`write_view`（2%）。`??` はインライン化などで `addr2line` から引けなかったぶんで、アロケータと `memcpy` まわりと見られる。

## 直したところ

### `pkg/tinymarkdown`: `cells` がセルごとに `StringBuilder` を作っていた

- 直す前は、セルごとに 1 文字ずつ `StringBuilder` に書いて `to_string` していた。セルごとにバッファと文字列を作ることになる。
- 区切りの `|` を `StringView::find` で次々に飛ばし、`\|` は `\` を含むセルのときだけ `replace_all` でほどく（`unescape_cell`）。`find` は位置を返すだけなので、確保せずに飛べる。

### `pkg/tinymarkdown`: `split_inlines` のクロージャと `trim_space` の確保

- `emit` クロージャをやめて、テキストとインラインをその場で push した。クロージャは呼ぶたびに捕捉した値を扱うので、ホットループでは外す。
- `trim_space` は `trim(chars=SPACES)` で文字集合を作っていた。`SPACES` は非 ASCII を含むので、`trim` は 1 文字ごとに集合の全要素と比べる実装になりうる。Go の `strings.TrimSpace` と同じ 2 文字種（`\t`〜`\r`、空白、Unicode の空白）を自分で見る `is_space_code` を書き、`trim_space` は `StringView` を返すようにした。返すのが view なので、残す行だけが `to_owned` する。
- `scan` の `para`・`quote`・`table`・`code` を `Array[StringView]` にした。`join("\n")` は `ToStringView` に対して総称なので、`Array[StringView]` のまま結合できる。`\r` を落とす `strip_suffix` も view を返す。
- `backquotes` は `trim_start(chars="\`")` で view と文字集合を作っていたのを、自分で数える形にした。`indent`・`is_heading`・`parse_heading` も同じ。
- `cells` の `is_delimiter` は `trim(chars="-")` で文字集合を作っていたので、前後の `:` を外して中身が全部 `-` かを見る形にした。

### `pkg/el`: タグと属性の組み立て

- 直す前は `"<\{name.0}"` や `" \{k}=\"{v}\""` を補間で作って `write_string` していた。タグと属性ごとに文字列が 1 つできる。
- `<`、タグ名、属性名、`="`、値、`"`、`>` を分けて書くようにした。`BoolAttr` の `" \{k}"` も空白と名前を分ける。組み立てのための文字列が消える。
- `write_escaped` は 1 文字ずつ `write_char` していたのを、エスケープが要る文字の間をまとめて `write_view` するようにした。`el` の `render_html` は出力を `StringBuilder` に貯めて最後に `to_string` するので、書き込みの回数がそのまま効く。

## 試して採らなかったもの

- `split_inlines` で次の `` ` `` か `[` まで `find` で飛ばす案: 大きく遅くなった。`StringView::find` は探すたびに view を作るので、1 文字ずつ見るほうが安かった。`emit` を外すだけにした。
- `write_char(' ')` などを `write_string(" ")` に置き換える案: native で 68.5 → 71.1 µs、wasm-gc で 191 → 194 µs と遅くなった。1 文字の書き込みは `write_char` のほうが速い。
- `StringBuilder(size_hint=1 << 20)` の先確保: native で 68 → 108 µs、wasm-gc で 191 → 625 µs と大きく遅くなった。大きい確保そのものが高い。残っている `moonbit_make_string`（`render_html` の 12%）は、最後の `to_string` が出力ぶんを 1 回確保するところで、これだけでは避けられない。

## 残っているところ

- `pkg/tinymarkdown`: `blit_from_string`（`StringBuilder` への写し）、`drop_object`、`malloc`/`free`。`scan` が段落の行を `join` で 1 つの `String` にするところは Go 版と同じく残っている。`split_inlines` は `Text`・`Code`・`Link` を enum に入れて `Array` に伸長するので、その確保も残る（Go 版の「`Inline` を構造体にする」実験に対応する形。まだ触っていない）。
- `pkg/el`: 出力文字列の確保（`moonbit_make_string`）と `write_escaped` の走査。`write_escaped` はまとめ書きにしたが、それでも 5 つの文字を毎回比べる。

## 次にやること

- `split_inlines` の結果のスライスを、`` ` `` と `[` の数から見積もって先に確保する（Go 版の実験で効いた手）。
- `make compare` で Go 版と一致することを確かめる。
- Go 版の `el` の実験（ライターを `io.StringWriter` にする）に対応する形は、MoonBit 版では `StringBuilder` がすでにその形なので、必要ない。
