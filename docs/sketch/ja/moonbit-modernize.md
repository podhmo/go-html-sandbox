# レポート: `moonbit/` の modernize

[moonbit-individual-handbook](https://github.com/podhmo/moonbit-individual-handbook) の `.agents/skills/moonbit-modernize` skill を、`moonbit/` のコードに適用した記録。
skill はこのリポジトリにも個人の環境にもインストールせず、handbook の手元の clone から SKILL.md を読み、その手順に沿って手で書き換えた（「仮想的に実行」）。
候補の洗い出しは、同じ handbook の `moonbit-modernize-explore` の手順に従った。

作業はブランチ `moonbit-modernize` で行い、書き換えの種類ごとに 1 コミットにした。どのような書き換えをしたかは、コミットを 1 つずつ見れば単独の diff として確かめられる。

## 結論

- 15 種類の書き換えを、それぞれ 1 コミットにして適用した。挙動は変えていない。各コミットの後で `moon fmt`、wasm-gc と native の両方での `moon check --deny-warn`、`moon test`（24 件）を通し、最後に `make check` も通した。
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
| 16ad098 | 警告 `unnecessary_view_op` | view が期待される場所の `[:]` を削除 |
| 860e083 | 警告 `unqualified_record` | `let` に束縛する struct リテラルを `LineWriter::{ .. }` のように型名付きにした |
| c670be4 | 構文 | 匿名関数 `fn(sb) { .. }` をアロー関数 `sb => ..` に |
| ce2881a | `<+` | builder に文字列リテラルやテンプレート文字列を書く `write_string` を `sb <+ ".."` に |
| 864eef9 | core の関数 | `join_url` の末尾の `/` を落とすループを `trim_end` に、区切り行の判定を `Iter::all` に、行の長さ合わせを `Array::truncate` と range の `for` に |
| 673ff02 | Option | `match x.strip_prefix(..) { Some(v) => v; None => x }` を `x.strip_prefix(..).unwrap_or(x)` に |
| ce221a8 | core の関数 | 先頭の `#` やバッククォートを数えるループを `trim_start` との長さの差に |
| dc93f4d | functional-for | `cells`、`nest`、`link`、`closing_run` の `let mut` + `while` を、`continue` と `nobreak` を使う functional-for に |
| a7255b3 | is-pattern | `c == '\n' \|\| c == '>'` を `c is ('\n' \| '>')` に |
| 61b365a | guard | `parse_table` と `link` の前提条件を `guard .. else { return None }` に |
| e7c776f | core の関数 | `filter(..).length()` を `count_if` に |
| 2f36799 | method | `is_void`、`is_block`（`Tag`）、`is_attr`、`write_html`、`write_plain`（`Node`）を method に。`html_response` は名前空間付きの constructor `Response::html(status, body~)` に |
| aa3c81b | ラベル付き引数 | 取り違えやすい先頭以外の引数にラベルを付けた（`compare(path, go~, moonbit~)`、`body_diff(go, moonbit~)`、`join_url(base, path~)`、`page(sb, title~, body~)`、`split_inlines(s, links~)`、`nest(flat, from~, level~)`、`closing_run(s, from~, n~)`） |
| 67a25f2 | 可視性 | 外のパッケージで構築していない `Response` と `Report` を `pub(all) struct` から `pub struct`（外からは読み取り専用）に |
| 9799259 | 慣用表現 | `xs.length() > 0` を `!xs.is_empty()` に（`compare` パッケージの書き方に揃えた） |

## 方針を決めたもの

- **`@pkg.` は残す。** `unnecessary_annotation` の 128 件（`@el.Text(..)` の `@el.` など）は、skill の方針どおり候補を見つけるためだけに使い、書き換えなかった。どのパッケージの名前かが見える方がよい。
- **`<+` は文字列リテラルとテンプレート文字列にだけ使う。** 変数をそのまま書く箇所（`Raw(s) => sb.write_string(s)`、`LineWriter::write`）は `write_string` のまま。`sb <+ s` は `unused_value` の警告になる。`write_string(line)` と `write_char('\n')` が続く箇所は、まとめて `sb <+ "\{line}\n"` にした。
- **ラベルは、同じ型の引数が並ぶ箇所と Bool / Int の引数にだけ付ける。** skill は「先頭以外の引数にはすべてラベルを付ける」としているが、`el(name, children)` や `escape_to(sb, s)` のように第 2 引数の役割が明らかなものは位置引数のままにした。とくに `el` は HTML を組み立てる DSL で、ノードごとに `children=` が入ると読みにくい。
- **`Fetched` は `pub(all)` のまま。** `compare/cmd` とテストが構築している。`tinymarkdown` の `Document`、`Block`、`Inline` と、`el` の型も、テストや利用側が値を作るので `pub(all)` のまま。

## 見送ったもの

- **`scan` と `split_inlines` のループ。** `split_inlines` は、ローカル関数 `emit` が可変の `text` を書き換えている。`scan` は `in_code` の状態を多くの分岐にまたがって持っている。functional-for にすると、`continue` のたびにすべての状態を書き並べることになり、元の方が読みやすい。
- **`compare/cmd` の `fetch` の `try { .. } catch`。** ブロックの中で `@http.get` と `body.text()` の 2 つが raise する。postfix の `f() catch { .. }` にすると catch が 2 つに分かれ、冗長になる。
- **`is_heading` を functional-for にすること。** 一度書いてみたが、本体が空の `for .. { } nobreak { n }` になって読みにくかったので、`trim_start` との長さの差で数える形（ce221a8）にした。
- **`body_diff` の 2 重ループのリスト内包表記化。** 内包表記は入れ子にできず（skill の pitfall にある）、`flat_map` で書いても読みやすくならない。
- **`Type::new`。** 該当する関数がなかった。

## 気づいたこと

- **functional-for の 3 部形式で `continue x` に値を渡すと、更新節（`i = i + 1`）は実行されない。** `cells` の `\|`（2 文字進める）を `continue i + 2` と書けたのはこのため。もし更新節が実行されたら、`\|` を含むセルのテストが失敗するはずだが、通った。
- **`moon fmt` は、長い `<+` の右辺を次の行に送る。** `details <+` で改行し、テンプレート文字列を次の行に字下げして置く。`write_string(..)` のときの括弧と末尾のカンマがなくなるので、行数は少し減る。
- **`String` は `StringView` が期待される場所で暗黙に変換される。** `line.strip_prefix("|").unwrap_or(line)` は、`strip_prefix` が `StringView?` を返し `line` は `String` だが、そのまま型が合った。
- **core の関数の細かい挙動は、`~/.moon/lib/core` の `pkg.generated.mbti` と実装を読んで確かめるのが早い。** `Array::truncate` は、指定した長さが今の長さ以上なら何もしないことを、実装で確かめてから使った。
- **`el` と `tinymarkdown` で、`derive` で生えるメソッドを打ち消す書き方が違う。** `el/extends.mbt` は `#deprecated` を付けて `pub extend` しているが、`tinymarkdown` は付けていない。modernize の catalog の範囲外なので、揃えてはいない。
