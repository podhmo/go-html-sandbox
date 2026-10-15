# レポート: `moonbit/` の modernize

[moonbit-individual-handbook](https://github.com/podhmo/moonbit-individual-handbook) の `.agents/skills/moonbit-modernize` skill を、`moonbit/` のコードに適用した記録。
skill はこのリポジトリにも個人の環境にもインストールせず、handbook の手元の clone から SKILL.md を読み、その手順に沿って手で書き換えた（「仮想的に実行」）。
候補の洗い出しは、同じ handbook の `moonbit-modernize-explore` の手順に従った。

作業はブランチ `moonbit-modernize` で行い、書き換えの種類ごとに 1 コミットにした。どのような書き換えをしたかは、コミットを 1 つずつ見れば単独の diff として確かめられる。

## 結論

- 15 種類の書き換えを、それぞれ 1 コミットにして適用した。挙動は変えていない。各コミットの後で `moon fmt`、wasm-gc と native の両方での `moon check --deny-warn`、`moon test`（24 件）を通し、最後に `make check` も通した。
- 最初のパスでは、handbook の `language-changes-catalog` にある 2 つの参照文書を読んでいなかった。後から照合し、さらに 8 種類を適用した（「追記: language-changes-catalog との照合」の節）。
- コードは移植したばかりで、もともとかなり今風に書かれていた。opt-in の警告で見つかった書き換えは 2 種類（6 箇所）だけで、残りはすべて、警告の出ない慣習（skill の catalog と grep）から見つけた。
- 公開 API が変わったのは `compare` パッケージ（引数のラベルと `Report` の可視性）と `site` パッケージ（`Response` の可視性）だけ。`pkg.generated.mbti` の diff がそのまま API の変更点になっている。
- 「適用できる」と「適用すべき」は別、という skill の判断基準に従い、読みにくくなるものは見送った（「見送ったもの」の節）。

## 環境

| | バージョン |
| --- | --- |
| moon | 0.1.20261012 |
| moonc | v0.10.15（2026-10-12） |
| moonbit-individual-handbook | a59f0d5（2026-09-28） |

## 手順

1. 対象のモジュールは `moonbit/` の 1 つだけ（`moon.mod` は 1 つ）。`posts/embedded.mbt` は生成物なので対象から外した。
2. 変更前に `moon fmt --check`、`moon check --deny-warn`（wasm-gc、native）、`moon test` が通ることを確かめた。
3. 今の toolchain の `off` の警告を `moonc check -warn-help` から取り出し、`missing_doc`、`missing_invariant`、`missing_reasoning`、`declaration_implemented` を除いて `--warn-list` に渡した。

   ```sh
   L=$(moonc check -warn-help | awk '$NF == "off" {print $1}' | sort -u \
     | grep -v -E '^(missing_doc|missing_invariant|missing_reasoning|declaration_implemented)$' \
     | paste -sd+ -)
   moon check --target native --warn-list "+$L"
   ```

   結果は `unnecessary_annotation` が 128 件、`unnecessary_view_op` が 8 件、`unqualified_record` が 4 件（どれも wasm-gc と native で重複して数えた件数）。
4. 警告の出ない候補は、`pkg.generated.mbti` を読むことと grep（`::new(`、`fn(`、`write_string`、`while`、`let mut`）で探した。
5. 候補を種類ごとにまとめ、種類ごとに方針を決めた。1 箇所で動くことを確かめてから残りを書き換え、検証してからコミットした。

## コミットの一覧

| commit | 種類 | 内容 |
| --- | --- | --- |
| 85ed177 | 警告 `unnecessary_view_op` | view が期待される場所の `[:]` を削除 |
| d4c45c7 | 警告 `unqualified_record` | `let` に束縛する struct リテラルを `LineWriter::{ .. }` のように型名付きにした |
| e1e9f8c | 構文 | 匿名関数 `fn(sb) { .. }` をアロー関数 `sb => ..` に |
| d1e314e | `<+` | builder に文字列リテラルやテンプレート文字列を書く `write_string` を `sb <+ ".."` に |
| 19afdde | core の関数 | `join_url` の末尾の `/` を落とすループを `trim_end` に、区切り行の判定を `Iter::all` に、行の長さ合わせを `Array::truncate` と range の `for` に |
| 163154c | Option | `match x.strip_prefix(..) { Some(v) => v; None => x }` を `x.strip_prefix(..).unwrap_or(x)` に |
| c5c2d32 | core の関数 | 先頭の `#` やバッククォートを数えるループを `trim_start` との長さの差に |
| 1b5db40 | functional-for | `cells`、`nest`、`link`、`closing_run` の `let mut` + `while` を、`continue` と `nobreak` を使う functional-for に |
| 8d70346 | is-pattern | `c == '\n' \|\| c == '>'` を `c is ('\n' \| '>')` に |
| 04766d7 | guard | `parse_table` と `link` の前提条件を `guard .. else { return None }` に |
| 6ac8b8a | core の関数 | `filter(..).length()` を `count_if` に |
| 2bfe25b | method | `is_void`、`is_block`（`Tag`）、`is_attr`、`write_html`、`write_plain`（`Node`）を method に。`html_response` は名前空間付きの constructor `Response::html(status, body~)` に |
| 9b7efdc | ラベル付き引数 | 取り違えやすい先頭以外の引数にラベルを付けた（`compare(path, go~, moonbit~)`、`body_diff(go, moonbit~)`、`join_url(base, path~)`、`page(sb, title~, body~)`、`split_inlines(s, links~)`、`nest(flat, from~, level~)`、`closing_run(s, from~, n~)`） |
| d1dbfb7 | 可視性 | 外のパッケージで構築していない `Response` と `Report` を `pub(all) struct` から `pub struct`（外からは読み取り専用）に |
| 057cb5a | 慣用表現 | `xs.length() > 0` を `!xs.is_empty()` に（`compare` パッケージの書き方に揃えた） |

## 方針を決めたもの

- **`@pkg.` は残す。** `unnecessary_annotation` の 128 件（`@el.Text(..)` の `@el.` など）は、skill の方針どおり候補を見つけるためだけに使い、書き換えなかった。どのパッケージの名前かが見える方がよい。
- **`<+` は文字列リテラルとテンプレート文字列にだけ使う。** 変数をそのまま書く箇所（`Raw(s) => sb.write_string(s)`、`LineWriter::write`）は `write_string` のまま。`sb <+ s` は `unused_value` の警告になる。`write_string(line)` と `write_char('\n')` が続く箇所は、まとめて `sb <+ "\{line}\n"` にした。
- **ラベルは、同じ型の引数が並ぶ箇所と Bool / Int の引数にだけ付ける。** skill は「先頭以外の引数にはすべてラベルを付ける」としているが、`el(name, children)` や `escape_to(sb, s)` のように第 2 引数の役割が明らかなものは位置引数のままにした。とくに `el` は HTML を組み立てる DSL で、ノードごとに `children=` が入ると読みにくい。
- **`Fetched` は `pub(all)` のまま。** `compare/cmd` とテストが構築している。`tinymarkdown` の `Document`、`Block`、`Inline` と、`el` の型も、テストや利用側が値を作るので `pub(all)` のまま。

## 見送ったもの

- **`scan` と `split_inlines` のループ。** `split_inlines` は、ローカル関数 `emit` が可変の `text` を書き換えている。`scan` は `in_code` の状態を多くの分岐にまたがって持っている。functional-for にすると、`continue` のたびにすべての状態を書き並べることになり、元の方が読みやすい。
- **`compare/cmd` の `fetch` の `try { .. } catch`。** ブロックの中で `@http.get` と `body.text()` の 2 つが raise する。postfix の `f() catch { .. }` にすると catch が 2 つに分かれ、冗長になる。
- **`is_heading` を functional-for にすること。** 一度書いてみたが、本体が空の `for .. { } nobreak { n }` になって読みにくかったので、`trim_start` との長さの差で数える形（c5c2d32）にした。
- **`body_diff` の 2 重ループのリスト内包表記化。** 内包表記は入れ子にできず（skill の pitfall にある）、`flat_map` で書いても読みやすくならない。
- **`Type::new`。** 該当する関数がなかった。

## 気づいたこと

- **functional-for の 3 部形式で `continue x` に値を渡すと、更新節（`i = i + 1`）は実行されない。** `cells` の `\|`（2 文字進める）を `continue i + 2` と書けたのはこのため。もし更新節が実行されたら、`\|` を含むセルのテストが失敗するはずだが、通った。
- **`moon fmt` は、長い `<+` の右辺を次の行に送る。** `details <+` で改行し、テンプレート文字列を次の行に字下げして置く。`write_string(..)` のときの括弧と末尾のカンマがなくなるので、行数は少し減る。
- **`String` は `StringView` が期待される場所で暗黙に変換される。** `line.strip_prefix("|").unwrap_or(line)` は、`strip_prefix` が `StringView?` を返し `line` は `String` だが、そのまま型が合った。
- **core の関数の細かい挙動は、`~/.moon/lib/core` の `pkg.generated.mbti` と実装を読んで確かめるのが早い。** `Array::truncate` は、指定した長さが今の長さ以上なら何もしないことを、実装で確かめてから使った。
- **`el` と `tinymarkdown` で、`derive` で生えるメソッドを打ち消す書き方が違う。** `el/extends.mbt` は `#deprecated` を付けて `pub extend` しているが、`tinymarkdown` は付けていない。modernize の catalog の範囲外なので、modernize のコミットでは揃えていない。その後、`tinymarkdown` にも `#deprecated` を付けて `el` に揃えた。deprecated になっているのは、`derive` したトレイトのメソッドが普通のメソッドとしても自動で生えるというコンパイラの挙動で、生えたメソッドを自分で消す方法はない。`#deprecated` を付けた `pub extend` は、警告 `implicit_impl_as_method` が示す「メソッドとしては使わせない」側の書き方で、`==` や `Debug::to_repr` だけを使うことをコンパイラに確かめさせられる。

## 追記: moonbit-refactoring skill の前半による見直し

[moonbitlang/moonbit-agent-guide の moonbit-refactoring skill](https://github.com/moonbitlang/moonbit-agent-guide/blob/main/moonbit-refactoring/SKILL.md) のうち、「Local refactoring」より前の節（Intent、Workflow、Improve Package Architecture、Minimize Public API and Modularize）に照らして、modernize の後のコード全体を見直した。
この節の内容は見直しの結果だけで、コードは変えていない。

skill の Workflow は「まず全体の構造を見て、構造が固まるまで局所的な書き換え（名前の変更やパターンマッチ）は避ける」としている。
一方、`moonbit-modernize` は局所的な書き換えのカタログで、今回はこれとは逆の順に進めた。
そこで、後からではあるが、全体の構造に問題がないかを確かめた。

### 結論

- パッケージの構成と依存関係に問題はなく、局所的な書き換えを先にしたことで困ることはなかった。
- 公開 API は、ほぼ呼び出し側が必要とするものだけになっている。`internal/` パッケージに分ける必要もない。
- skill の Intent にある「view 型でコピーを避ける」は、`tinymarkdown` にまだ余地がある。
- テストのカバレッジは 386/411 行。残りは主に `worker`（テストなし）と `compare` のエラー経路。公開 API に、doc コメント中のテスト（`mbt check` のコードブロック）はない。

### パッケージ構成と依存関係

| パッケージ | ソース（行） | テスト（行） | import しているもの | 使っているパッケージ |
| --- | --- | --- | --- | --- |
| `el` | 441 | 163 | なし | なし（テストのみ） |
| `tinymarkdown` | 423 | 403 | `core/debug`（テストのみ） | なし（テストのみ） |
| `posts` | 生成物 200 | 32 | なし | なし（テストのみ） |
| `site` | 67 | 28 | なし | `worker` |
| `worker` | 52 | 0 | `site` | Workers の JS |
| `compare` | 155 | 119 | `core/diff` | `compare/cmd` |
| `compare/cmd` | 73 | 0 | `compare`、`core/argparse`、`core/string`、`moonbitlang/async` | なし（実行ファイル） |

- 依存関係に循環はなく、上位のパッケージが下位を import する向きだけになっている。
- 規模は skill の目安（パッケージ 1 万行、ファイル 2 千行、関数 200 行）よりずっと小さい。一番長い関数は `tinymarkdown` の `scan` で 84 行。
- `el`、`tinymarkdown`、`posts` は、まだどのパッケージからも使われていない。`site` がこれらを使うのは TODO.md の「ブログを MoonBit で作り直す」の残りのステップで、移植の途中だから。
- そのため `site` には、`el` のエスケープと同じ役割の `write_escaped` が別にある。エスケープ結果も違い、`"` を `el` は Go の `html.EscapeString` と同じ `&#34;` に、`site` は `&quot;` にする。`site` を `el` で書き直せば、この重複はなくなる。
- バックエンドの切り替えは、どちらも `moon.pkg` の `supported_targets` で揃っている（`worker` は wasm-gc のみ、`compare/cmd` は native のみ）。ファイル名の接尾辞や `#cfg` は使っていない。

### 公開 API

- `site` の `Response::html`、`el` の各ヘルパー、`tinymarkdown` の `scan`、`nest`、`cells` などは、すべてパッケージ内に閉じている。
- `worker` の `path_push` と `serve` は、Wasm から export するために `pub` が必要。
- `compare` の `body_diff` を使っているのは、`compare` 自身とテストだけ。`pub` を外すこともできる。ただしその場合、ブラックボックステストからは `compare` 経由でしか確かめられなくなる。skill はブラックボックステストを勧めているので、`pub` のままにした。
- `el` の `const.mbt` にある要素名や属性名（`div`、`href` など）は、ほとんどがまだ使われていない。HTML を組み立てる DSL の語彙なので、そのまま残す。
- 呼び出し元の洗い出しには `moon ide find-references` を使った。このコマンドは `--target` を付けないと `moon.mod` の `preferred_target`（wasm-gc）で解析する。そのため、native でしかビルドしない `compare/cmd` からの参照が出てこない。たとえば `default_paths` は、そのままだとテストの 1 件しか見つからず、`--target native` を付けて初めて `compare/cmd/main.mbt` の参照が見つかった。

### view 型とコピー

skill の Intent は「view 型（`StringView` など）でコピーを避ける」としている。
modernize のコミットでは、`[:]` を削り、`strip_prefix` の結果を view のまま扱うところまでで止めた。`tinymarkdown` には、まだ `to_owned()` が 9 箇所ある。

- `trim_space` は `StringView` を受け取るが、`String` を返す。`cells(line : String)` と `code_text(s : String)` も `String` を受け取るので、呼び出し側が先に `to_owned()` している。
- `split_inlines` と `link` は、`Text`、`Code`、`Link` に入れる部分文字列を切り出すたびにコピーしている。

`Block` と `Inline` は `String` を持つので、木に入れる時点でのコピーは必要になる。
減らせるのは、途中のヘルパーが `String` を受け取っているために起きるコピーで、`cells` と `code_text` が `StringView` を受け取るようにすれば減る。
ただ、`tinymarkdown` の目的は Go 版と同じ挙動の移植で、性能の問題もまだない。そのため手を付けていない。

### テストとドキュメント

`moon test --enable-coverage` の結果は 386/411 行。主な残りは次のとおり。

- `worker`（0/18 行）: host の import を呼ぶので、`moon test` では確かめられない。`make dev` と `make compare` で確かめている。
- `compare`（53/59 行）: 改行も `>` もない末尾の断片、`\r` と `\t` の表示、MoonBit 側だけの取得失敗。
- `tinymarkdown/inline.mbt`（71/72 行）: 1 行。

公開 API に、doc コメント中のテスト（`mbt check` のコードブロック）はない。
テストはすべて、Go のテストケースを移したブラックボックステスト（`*_test.mbt`）になっている。
modernize で変えた公開 API（`compare` のラベル、`Response` と `Report` の可視性）は README に書かれておらず、README を直す必要はなかった。

## 追記: language-changes-catalog との照合

最初のパスは、`moonbit-modernize` と `moonbit-modernize-explore` の SKILL.md にある catalog、opt-in の警告、grep だけを手がかりにしていた。
`moonbit-modernize` は自分の catalog を「前回うまくいったものの標本で、全体ではない」と書いている。それにもかかわらず、全体にあたる `language-changes-catalog` の 2 つの参照文書は読んでいなかった。

- `references/language-changes.md`: release notes から集めた「問題意識 → 言語機能」の catalog。
- `references/about-idiomatic-code.md`: 知識の階層の整理と、個人ポリシー。

そこで、この 2 つを読み、テーマ別 catalog の項目と個人ポリシーをひとつずつコードに当てはめた。
構文は、スクラッチのモジュールで今の toolchain（moon 0.1.20261012）でも通ることを確かめてから使った。

### 適用したもの

| commit | catalog の項目 | 内容 |
| --- | --- | --- |
| 2037cdd | 型・値「`const`」 | `tinymarkdown` の `fence`、`max_level`、`spaces` を `const` の `FENCE`、`MAX_LEVEL`、`SPACES` に |
| 965597e | パターンマッチング「配列パターンの `..rest`」 | `parse_table` の `lines[0]`、`lines[1]`、`lines[2:]` を `guard lines is [header, delim, .. body]` に |
| 36912bc | パターンマッチング「文字列パターン」 | リストの行を `trimmed is [.. "- ", .. rest]` で、両端の空白を落とすコードスパンを `s is [' ', .. inner, ' ']` で判定 |
| a955ed2 | ループ「`for x in expr`」 | テストの `for c in cases { let (name, src, want) = c` を `for (name, src, want) in cases` に |
| 8f443d2 | ループ「リスト内包」 | `posts` のテストの `.iter().map(f => f.0).collect()` を `[for f in @posts.files => f.0]` に |
| b81b058 | エラー処理「Result 化」と個人ポリシー「raise が既定」 | `compare/cmd` の `fetch` を raise する関数にし、失敗をデータとして残す `try_fetch` を `Ok(fetch(url)) catch { e => Err(..) }` の薄い層として分けた。閉じたポートに向けて CLI を実行し、両側の失敗が報告されることを確かめた |
| 1990fe1 | メソッド「外部型へのローカルメソッド」 | `el` の `escape_to(sb, s)` と `site` の `write_escaped(sb, s)` を、パッケージ内だけの `StringBuilder::write_escaped` に |
| 5a9d51b | 文字列「補間」 | `compare` の `header + details.to_string()` と、`tinymarkdown` のリスト項目の継続行の `+` 連結を、テンプレート文字列に |

### 当てはまらなかったもの、見送ったもの

- **正規表現（`lexscan`、`=~`）:** `tinymarkdown` のインライン解析は、トークナイザとして書き直せる。ただし Go 版と同じ挙動の移植が目的で、書き直しが大きいので見送った。
- **`<?`、カスケード `..`、ラベル付きブロック、`[| .. |]`、`extenum`、ローカル型、phantom type、ビット列パターン、`defer` / `errdefer`、`suberror`、`#non_exhaustive`、FFI の注釈:** どれも使う場面がなかった。
- **`fn Type::Type`:** 構築用の関数は、名前空間付きの `Response::html` しかない。
- **`#as_free_fn`:** 最初のパスでメソッドにした関数は、どれもパッケージ内に閉じていて、移行させる呼び出し元がない。
- **`ReadOnlyArray` / `FixedArray`:** `prefer_readonly_array` / `prefer_fixed_array` の警告は出なかった。
- **`trim_space` のローカルメソッド化:** `StringView` のメソッドにすると、`String` の値から呼ぶときに変換が要るので見送った。
- **`|` と `>` の行の判定:** 束縛する値がないので、`has_prefix` の方が読みやすい。
- **個人ポリシー「主要な引数以外はラベル付きにする」との差:** 最初のパスでは、`el(name, children)` の `children` のような、役割の明らかな第 2 引数を位置引数のまま残した（`escape_to(sb, s)` はメソッド `sb.write_escaped(s)` になり、self の直後は位置引数でよいという精緻化の側に入った）。個人ポリシーはこれもラベル付きにする側なので、方針が分かれている。`el` は HTML を組み立てる DSL で、ノードごとに `children=` が入ると読みにくいため、そのままにしている。
- **`mbt check` の doc テスト:** 「テストとドキュメント」の節のとおり、まだない。

### 気づいたこと

- catalog の多くは、警告ではなく「この問題にはこの機能がある」という当たりを付けるための知識だった。今回適用した 8 種類は、どれも警告が出ない。
- 文字列パターンは `Char` 単位で進み、`s[i]` や `s[n:]` は UTF-16 のコード単位で数える。リテラルで判定する形（今回の `[.. "- ", .. rest]`、`[' ', .. inner, ' ']`）は、書き換えても結果が同じになる。一方、位置で数える形は変わる。`s[2:]` を `[_, _, .. rest]` にすると、BMP 外の文字が先頭にあるときに結果がずれ、警告も出ない。たとえば `"😀ab"` では、`s[2:]` は `"ab"`、パターンの `rest` は `"b"` になる（moon 0.1.20261012 で確認）。
- 配列への複合代入 `items[i] += ".."` も、今の toolchain で書けた。

## 追記: handbook に戻したもの

このパスで得た知見のうち、skill に戻せるものを [podhmo/moonbit-individual-handbook#63](https://github.com/podhmo/moonbit-individual-handbook/pull/63) に draft として出した。

handbook の modernize は、2 段階に分かれている。

- **浅い版:** `moonbit-modernize` の catalog と警告だけで進める。
- **深い版:** `language-changes-catalog` を見て入念に見直す。

この使い分けはそのまま残し、浅い版には機械的に適用できるものだけを足した。

- **`moonbit-modernize` の Pitfalls:**
  - 3 部形式の functional-for で `continue e` に値を渡すと、更新節は実行されない。
  - 文字列パターンは `Char` 単位で進み、添字は UTF-16 のコード単位で数える。
- **`moonbit-modernize` の Step 2:** 深い版で見つけた書き換えのうち、設計の判断が要らないもの 6 種類（`const`、配列パターン、文字列パターン、for-in での分解、内包表記、テンプレート文字列）を足した。
- **`moonbit-modernize` の Step 3 と `moonbit-modernize-explore`:**
  - `moon info` を毎回実行し、`git diff --exit-code -- '*.mbti'` で確かめる。
  - `moon ide find-references` は、`--target` を付けないと `preferred_target` しか解析しない。

深い版に残したのは、設計の判断が要る 2 つ。

- raise を既定にし、`Ok(..) catch` の薄い層を分けること。
- 外部型へのローカルメソッド。

`moon fmt` が長い `<+` の右辺を次の行に送る件は、見た目だけの話で Pitfalls の選定基準に合わないので、入れていない。

## 追記: opt-in の警告を `moon.mod` で有効にした

`moonc check -warn-help` で `off` の警告を 1 つずつ `moon.mod` の `warnings` に入れ、`moon check --target all` で数えた（moon 0.1.20261012）。
件数があったのは `unnecessary_annotation`（148 件）と `missing_doc`（118 件）だけで、ほかは 0 件だった。

次の 8 つを `warnings` に入れた。今は 0 件なので、普段の `moon check` で新しく書いたコードの書き換えの候補だけが見える。

- `unnecessary_view_op`、`unqualified_record`、`unqualified_local_using`
- `unused_optional_argument`、`unused_default_value`
- `result_error_return`、`ambiguous_range_direction`、`deprecated_for_in_method`

入れなかったもの:

- `unnecessary_annotation`: `@pkg.` を残す方針なので。
- `missing_doc`: 公開していない補助関数にも doc を求めることになるので。
- `prefer_readonly_array`、`prefer_fixed_array`: 移植では Go のスライスを `Array` のまま持つので。
- `missing_invariant`、`missing_reasoning`、`declaration_implemented`: 手順の 3 と同じ理由で。

## 追記: 2 回目のパス

1 回目のパスの後に、`picoel`、`tinyfrontmatter`、`site` の大部分（`content.mbt`、`links.mbt`、`views.mbt`）、`repodocs`、`assets` が加わった。
そこで、同じ skill を、同じく「仮想的に実行」する形でもう一度当てた。作業はブランチ `moonbit-modernize-2` で行い、書き換えの種類ごとに 1 コミットにした。

| | バージョン |
| --- | --- |
| moon | 0.1.20261012 |
| moonbit-individual-handbook | 0c35763（#63 を取り込んだ後） |

### 結論

- 11 種類の書き換えを 12 コミット（for-in の分解は、拾い漏れを後から足したので 2 コミット）と、doc コメントの修正 1 コミットにした。挙動は変えていない。各コミットの前に `moon fmt` と `moon info` を実行し、`make check`（wasm-gc と native の `moon check`、`moon test` 59 件、`.mbti` の差分確認）を通した。
- opt-in の警告で見つかったのは `unnecessary_annotation` の 90 件（すべて `@el.`）だけで、方針どおり書き換えなかった。今回の書き換えも、すべて skill の catalog と grep、`.mbti` から見つけたもの。
- 公開 API が変わったのは `picoel`（引数のラベル）と `site`（`Site::new` → `Site::Site`、`Site` を抽象型に）だけ。

### Step 0: 全体の構造の確認

skill の Step 0 に従い、`moonbit-refactoring` の「Local refactoring」より前の観点で、新しいパッケージを先に見た。

- 依存関係は `worker` → `site` → `picoel` / `el` / `tinymarkdown` / `tinyfrontmatter` / `posts` / `repodocs` / `assets` の一方向で、循環はない。
- `site` は 4 ファイル、約 1,100 行。`links.mbt` は Go の `net/url` と `path` の一部の移植を含むが、使うのは `site` だけなので、パッケージを分けるほどではない。
- 公開 API のうち、`Site` のフィールド（`by_slug` などの索引）は外から読まれていなかった。これは書き換えの 1 つとして `Site` を抽象型にした（9034696）。`Post` と `Doc` のフィールドはテストが読むので `pub struct` のまま。

構造を変える必要はなかったので、そのまま局所的な書き換えに進んだ。

### コミットの一覧

| commit | 種類 | 内容 |
| --- | --- | --- |
| 6a30d6c | constructor | `Site::new` を `Site::Site` に。呼び出しは `@site.Site(..)` |
| e013948 | for-in の分解 | `for c in xs { let (a, b) = c` と、ヘッダの `h.0` / `h.1` を `for (a, b) in xs` に |
| 9255055 | functional-for | `tinyfrontmatter` の `split`（`for rest, lineno` と `nobreak` での raise）、`unescape`（`continue i + 3` / `continue end`）、`parse_ref` の scheme の走査（`break (scheme, rest)`）、`post_name`（for-in の累積変数 `prev_dash`） |
| 1d3b637 | core の関数 | `check_date` の桁の計算を `Iter::fold` に、制御文字の検査を `Iter::any` に、最小値を `Int::min` に、ホストの検査を `contains_any(chars="/?#")` に |
| a8e83bf | リスト内包 | `load_docs` の `iter().filter(..).to_array()` を `[for f in files if .. => f]` に |
| 9e99235 | 文字列パターン | `Site` のホストの取り出しを `[.. "https://", .. h] \| [.. "http://", .. h]` に、`parse_ref` の `rest[2:]` を `[.. "//", .. after]` に |
| 2f1d019 | 範囲パターン | `hex_value` の `to_int()` の比較を `'0'..<='9'` などの範囲パターンに |
| 294221a | method | `post_source`、`post_path`、`post_markdown_path`、`doc_path`、`doc_markdown_path` を `Post::source`、`Post::page_path`、`Post::markdown_path`、`Doc::page_path`、`Doc::markdown_path` に。`parse_ref` は名前空間付きの constructor `Ref::parse` に |
| aea0dcb | ラベル付き引数 | `meta_name(name, content~)`、`meta_property(property, content~)`、`icon(href, mime_type~)`、`download_link(href, filename~, children)`、`spread(start, end~)`、`page_header(info, href~, filename~)` |
| 9034696 | 可視性 | `pub struct Site` を `struct Site`（抽象型）に |
| 09c2132 | for-in の分解 | e013948 で拾い漏れた、テストの `c.0` / `c.1` と、`@posts.files` / `@repodocs.files` の内包表記 |
| 3627e2a | 外部型へのローカルメソッド | `escape` と `hex_escape_non_ascii` で重複していた `%XX` の書き込みを `StringBuilder::write_percent_encoded` に |
| 569ae6b | doc コメント | `front_matter_keys` と `doc_sources` の doc コメントが `FRONT_MATTER_KEYS` / `DOC_SOURCES` と `const` のように書いていたのを、実際の名前に。配列は `const` にできないので `let` のまま |

### 方針を決めたもの

1 回目のパスの方針（`@pkg.` は残す、ラベルは同じ型の引数が並ぶ箇所にだけ付ける、`el` の DSL の `children` は位置引数のまま）をそのまま使った。

- **ラベル:** `picoel` の `a(href, children)` や `table(header, rows)` は、引数の型が違うので取り違えようがなく、位置引数のままにした。
- **method の名前:** `Doc` にはフィールド `path`（`/docs/` より下の URL のパス）があるので、ページの URL を返すメソッドは `path` ではなく `page_path` にした。`Post::source` は、`Doc` のフィールド `source` と同じ意味（リポジトリ内のファイルのパス）になるように付けた。

### 見送ったもの

- **`post_list` と `doc_list` の `push` のループ。** 内包表記にすると `[h1, ..[for p in posts => { .. }]]` と入れ子が深くなり、元のループより読みにくかった。一度書き換えてから戻した。
- **`ogp` のメソッド化。** 引数は呼び出し側で組み立てたレコード（`{ ..meta, title, description }`）で、メソッドにするとレコードリテラルにメソッドを続ける形になる。
- **`render_blocks` の `bs.map(b => ..)`。** 内包表記と同じ意味で、書き換えても読みやすさは変わらない。
- **テストの複数行の文字列を `#|` にすること。** Go のテストケースの文字列をそのまま移しているので、Go 版と見比べやすい今の形にした。
- **`worker` の `put_string` の添字のループ。** UTF-16 のコード単位を 1 つずつ host に渡すという意図が、添字のループで一番はっきり読める。

### 気づいたこと

- **2 部形式の functional-for（`for i = 0; cond; { .. }`）で、本体の末尾まで `continue` なしで落ちると、状態を変えないまま次の周回に入る。** ほかの分岐に `continue e` が 1 つでもあれば警告は出ず、無限ループになる（どこでも更新しないときだけ `unused_loop_variable` の警告が出る）。`split` を書き換えたとき、本体の最後に `continue next, lineno + 1` を置いたのはこのため（moon 0.1.20261012 で確認）。
- **`UInt16` の値にも、Char のリテラルの範囲パターン（`'0'..<='9'`）がそのまま使える。** `s[i] == '%'` と同じく、リテラルの型が `UInt16` として推論される。`hex_value` は `to_char()` を挟まずに書けた。
- **ラベル付きの引数を持つ関数は、ローカル変数に束縛して呼べない。** `let prop = @picoel.meta_property` の後に `prop(.., content=..)` と書くと、エラー 4117「Function with labelled arguments can only be applied directly」になる。`ogp` は `@picoel.meta_property(..)` を直接呼ぶ形にした。
- **内包表記の `for` も、for-in と同じくタプルのパターンを取れる。** `[for (name, _) in @posts.files => name]` と書けた。
- **for-in の分解は、1 つのコミットで拾い切れなかった。** 最初の grep は `for c in xs {` の次の行の `let (..) = c` だけを探していて、本体で `c.0` を直接読む形を見落とした。`[^a-zA-Z_.][a-z_]+\.[0-9]\b` で探し直して見つけた。
