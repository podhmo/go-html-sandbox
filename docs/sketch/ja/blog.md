# スケッチ: モバイルファーストなブログ（アプリケーション例）

## 目的

**スマートフォンで快適に読める SSR のブログ**を、アプリケーションの例として 1 つ作る。
記事は、ごく簡単な Markdown（見出しによるセクション、箇条書き、段落、コードブロックだけ）で書く。

制約:

- 依存は標準ライブラリのみ。
- CSS の変換・ビルド工程を入れない（Tailwind、Sass、PostCSS などは使わない）。
- `go:embed` は favicon と記事（Markdown ファイル）を埋め込むことにだけ使う。バイナリ 1 つで動くようにする。
- レイアウト（HTML の骨格と CSS）は、Go の関数で Node を組み立ててレンダリングする。テンプレートファイルは使わない。
- JavaScript は使わない。

## アプリケーションとライブラリの分担

| | 置き場所 | 責務 |
| --- | --- | --- |
| ライブラリ: HTML | `pkg/el` | [設計方針](../../ja/design.md)の内容。Node、Renderer、要素名・属性名の const |
| ライブラリ: Markdown | `pkg/tinymarkdown` | ごく簡単な Markdown を構文木（純粋なデータ）に変換する。`pkg/el` には依存しない |
| アプリケーション | `cmd/blog/main.go` | 記事の読み込み、ルーティング、レイアウト、構文木から Node への変換、CSS、favicon の配信 |

- 依存の向きは `cmd/blog` → `pkg/el` と `cmd/blog` → `pkg/tinymarkdown` だけにする。ライブラリ同士は依存させない。
- 構文木を Node に変換する処理は、HTML の出し方（`<section>` を使うか、見出しに id を付けるか など）を決める部分なので、アプリケーション側に置く。数十行で済む見込み。
- `pkg/el` に足りない要素名・属性名が見つかったら、ライブラリへの追加として扱う。今だけ必要なものは `el.AttrName("...")` でキャストして使える。

## `pkg/tinymarkdown`: ごく簡単な Markdown パーサー

### 対応する書き方

| 書き方 | 意味 |
| --- | --- |
| `# 見出し` 〜 `### 見出し` | セクションの開始。`#` の数がセクションの深さ |
| `- 項目` | 箇条書きの 1 項目。連続する行が 1 つのリストになる |
| ` ``` ` で始まる行から ` ``` ` だけの行まで | コードブロック。中身は一切解釈せず、そのまま保持する |
| それ以外の空でない行 | 段落。連続する行は 1 つの段落にまとめる |
| 空行 | 段落やリストの区切り |

コードブロックの扱い:

- 開始行は ` ``` ` で始まる行。` ``` ` の後ろの文字列（例: ` ```go ` の `go`）は読み飛ばす。シンタックスハイライトはしないので言語名は使わない。
- 終了行は ` ``` ` だけの行（前後の空白は無視する）。
- バッククォートは 3 つ固定。` ```` ` のように 4 つ以上で囲む書き方や、` ~~~ ` には対応しない。
- 中身の行は、`#` や `- ` で始まっていてもセクションや箇条書きにしない。空行も中身として保持する。
- 終了行がないまま文書が終わったら、そこまでをコードブロックとする。

対応しないもの（明示的に範囲外とする）:

- インライン記法（強調、リンク、コード）。テキストはすべてそのまま文字列として扱う。
- 入れ子の箇条書き、番号付きリスト、引用、表、画像、HTML の直書き。
- 4 つ以上のバッククォートや `~~~` によるコードブロック、インデントによるコードブロック。

### 構文木の案

設計方針の「Node は純粋なデータ」にならい、構文木も描画ロジックを持たない値にする。

```go
package tinymarkdown

// Document is the root of a parsed document.
type Document struct {
	Children []Block
}

// Block is a marker interface for block-level nodes.
type Block interface{ block() }

// Section is a heading together with everything up to the next heading
// of the same or a shallower level.
type Section struct {
	Level    int    // 1..3
	Title    string
	Children []Block
}

type Paragraph struct{ Text string }

type List struct{ Items []string }

type CodeBlock struct {
	Code string // lines between the fences, joined with "\n"
}

func Parse(src string) Document
```

- 見出しを単なる 1 行として扱わず、`Section` として子要素を持つ入れ子の木にする。これで `<section>` の入れ子にそのまま対応させられる。
- 最初の見出しより前にある段落やリストは、`Document.Children` に直接入れる。
- 構文エラーは起こらない（解釈できない行はすべて段落として扱う）ので、`Parse` は `error` を返さない。
- テストは入力と期待する構文木の組を並べ、`reflect.DeepEqual` で比較する。

## `cmd/blog`: アプリケーション

### 画面とルーティング

Go 1.22 以降の `http.ServeMux` のパターンを使う。

| ルート | 内容 |
| --- | --- |
| `GET /{$}` | 記事一覧（新しい順）。タイトルと日付 |
| `GET /posts/{slug}` | 記事本文 |
| `GET /favicon.svg` | `go:embed` で埋め込んだ favicon |
| `/`（上のどれにも当たらないもの） | 404 のエラーページ |

### 記事の置き場所

記事は `cmd/blog/posts/` に置き、`go:embed` でバイナリに埋め込む。

```go
//go:embed posts/*.md
var postsFS embed.FS
```

- 記事を読む関数は `fs.FS` を受け取る形にする（`loadPosts(fsys fs.FS) ([]Post, error)`）。本番では `fs.Sub(postsFS, "posts")` を渡し、テストでは `fstest.MapFS` を渡せる。
- ファイル名は `2026-10-14-hello.md` の形にし、日付とスラッグをファイル名から取る。
- タイトルは最初の `#` 見出しから取る。
- 記事は起動時に一度だけ全部読む。記事を書き換えたら再ビルドが必要になる（ブログの例としてはこれで十分）。

### レイアウトは Go の関数

```go
func layout(title string, body ...el.Node) el.Node // <!doctype>、<head>、<header>、<main>、<footer>
func postList(posts []Post) el.Node
func postPage(p Post) el.Node
func renderBlocks(bs []tinymarkdown.Block) []el.Node    // 構文木を Node に変換する
```

- `<head>` には次を入れる。
  - `<meta name="viewport" content="width=device-width, initial-scale=1">`
  - `<meta name="color-scheme" content="light dark">`
  - `<link rel="icon" href="/favicon.svg" type="image/svg+xml">`
- CSS は Go の文字列定数として持ち、`layout` の中で `<style>` に `Raw(css)` で埋め込む。設計方針の「`Raw()` は静的な CSS など信頼できる文字列のみ」の実例になる。
- 記事本文はすべて `Text()` を通すので、Markdown に HTML が書かれていてもエスケープされる。コードブロックの中身も同じ。
- コードブロックは `<pre>` にするだけ。シンタックスハイライトはしない。
- 描画は `render(w, status, node)` の 1 箇所にまとめる（設計方針の 6）。エラーページもこれを通す（下記）。

### エラーメッセージの表示

エラーも素のテキストではなく、ほかの画面と同じ `layout` で HTML のページとして返す。

```go
func errorPage(status int, message string) el.Node
func renderError(w http.ResponseWriter, r *http.Request, status int, message string, err error)
```

| 状況 | ステータス | 利用者に見せるメッセージの例 |
| --- | --- | --- |
| 存在しない記事（`/posts/{slug}` に該当なし） | 404 | 「記事が見つかりませんでした」 |
| どのルートにも当たらない URL | 404 | 「ページが見つかりませんでした」 |
| 描画中のエラー、ハンドラ内の panic | 500 | 「表示中にエラーが起きました」 |

- エラーページには、ステータスコード、短いメッセージ、記事一覧（`/`）へ戻るリンクを出す。
- 利用者に見せるのは決まった文言だけにする。`err` の中身（ファイルパスなど内部の情報）は画面に出さず、`log/slog` でサーバーのログにだけ書く。
- 404 の判定は、`/posts/{slug}` のハンドラで記事が見つからなかった場合と、`/` に登録した最後の受け皿のハンドラの 2 か所で行う。
- panic は、`ServeMux` 全体を包む小さなミドルウェアで `recover` して 500 ページにする。
- **描画は一度 `bytes.Buffer` に書いてから送る。** `ResponseWriter` に直接ストリーム出力すると、途中でエラーが起きた時点でステータス 200 が送信済みになり、500 ページに切り替えられないため。記事は小さいので、バッファしても問題にならない。あわせて `Content-Length` も付けられる（設計方針「拡張の方向性」の最適化）。
- メソッドが合わない場合（例: `POST /`）は、`ServeMux` が返す 405 の素のテキストのままにする。読むだけのブログでは、ブラウザから普通に操作して起きることはないため。
- 起動時の記事読み込みのエラー（ファイル名が `YYYY-MM-DD-slug.md` の形でない、スラッグが重複している など）は、画面ではなくログに出してプロセスを終了する。

### モバイルファーストの CSS（変換なし）

ブログは読むのが主なので、読みやすさを中心に少ない行数で済ませる。

- 狭い画面を基準に書き、`@media (min-width: 40rem)` で広い画面向けに余白を足す。
- 本文の幅は `max-inline-size: 40rem` 程度、行間は 1.7 前後にする。
- `clamp()` で見出しの文字サイズを画面幅に合わせて変える。
- `prefers-color-scheme` でダークモードに対応する。
- 一覧のリンクはタップしやすいよう、行全体をリンクにして高さを 44px 以上にする。
- コードブロックは折り返さず、`overflow-x: auto` で横スクロールさせる（狭い画面で本文の幅を崩さないため）。
- カスタムプロパティで色と余白をまとめる。全体で 100 行以内を目安にする。

### favicon

```go
//go:embed favicon.svg
var favicon []byte
```

- SVG 1 つだけにする（`.ico` は作らない）。
- `Content-Type: image/svg+xml` と、適度な `Cache-Control`（例: `max-age=86400`）を付けて返す。
- `embed` で持つファイルは更新時刻がゼロ値なので、`http.ServeContent` に頼らず、直接 `w.Write` で返す。

### テスト

- `pkg/tinymarkdown`: 入力と構文木の組を並べたテーブルテスト。
- `cmd/blog`: `fstest.MapFS` に記事を入れてハンドラを作り、`httptest` で一覧・記事・favicon を確認する。エラーは、存在しない記事と存在しない URL が 404 のエラーページになること、panic するハンドラが 500 のエラーページになり、本文に内部の情報が出ないことを確認する。本文の確認には `PlainRenderer` を使う。

## ディレクトリ構成の案

```
cmd/blog/
  main.go           // 起動、フラグ、ServeMux の組み立て
  favicon.svg
  main_test.go
  posts/            // 記事。go:embed で埋め込む（例: 2026-10-14-hello.md）
pkg/el/             // HTML ライブラリ（設計方針の内容）
pkg/tinymarkdown/
  tinymarkdown.go
  tinymarkdown_test.go
```

最初は `main.go` 1 ファイルに収め、長くなったら `layout.go` などに分ける。

## 進める順序

1. `pkg/el`（設計方針の内容。ブログで使う範囲から）
2. `pkg/tinymarkdown`（セクション、箇条書き、段落、コードブロック）とテスト
3. `cmd/blog`: 記事一覧と記事ページ。CSS は最低限
4. `cmd/blog`: エラーページ（404 と 500）
5. `cmd/blog`: favicon、モバイル向けの CSS の仕上げ、テスト
