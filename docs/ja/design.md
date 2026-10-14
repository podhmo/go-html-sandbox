# メモ: Go 標準ライブラリだけの SSR 設計方針

## 目的

Go の標準ライブラリだけで、古典的な SSR（サーバサイドレンダリング）の Web サービスを作る。gomponents の思想を取り入れるが、依存はゼロ。テンプレートエンジン（`html/template`）も使わない。

## 信念・原則

### 1. 依存は標準ライブラリのみ
- `html`, `io`, `net/http`, `log/slog`, `fmt` だけで完結させる。
- 外部モジュールを足さない。gomponents は「思想の参照元」であって依存先ではない。

### 2. Node は純粋なデータ
- `Node` はマーカーインタフェース（`node()` メソッドだけ）。
- 具象ノード（`TextNode`, `ElementNode`, `AttrNode` など）は **描画ロジックを持たない**。
- 値型（`string` ラップや構造体）にして、`reflect.DeepEqual` や `==` で比較・テストしやすくする。
- `Node` に `Render` メソッドを生やさない。描画は Node の責務ではない。

### 3. 描画は Renderer（visitor パターン）
- `Renderer` インタフェースが各ノード型ごとのメソッドを持つ。
- `Render(w io.Writer, n Node, r Renderer)` が型 switch で 1 箇所にディスパッチする。
- ノード種を増やすときに触るのは「`Render` の switch」と「各 Renderer」だけ。
- **出力形式を差し替え可能**にする:
  - `HTMLRenderer` … 正しい HTML5
  - `PlainRenderer` … タグ・属性を捨ててテキストだけ抽出
  - 将来: Pretty 出力、サニタイザ、XML、Markdown なども同じ Node ツリーから作れる
- Renderer はゼロ値で安全に使えるようにする。

### 4. 要素・属性は const だけ
- ヘルパー関数（`Div()`, `Class()` など）を **生やさない**。
- `Tag` / `AttrName` という別々の型を定義し、`const` で要素名・属性名を列挙する。
- 唯一の生成関数は `El(name Tag, children ...Node)` と `Attr(key AttrName, val string)`。
- 型が違うので `El(Class, ...)` のような取り違えはコンパイルエラーで防げる。
- 新しい要素・属性は `const` を 1 行足すだけ。動的な名前は `Tag("my-widget")`, `AttrName("data-id")` でキャストして渡す。

### 5. HTML の正しさを守る
- `Text()` は必ず `html.EscapeString` を通す（XSS 対策）。
- `Raw()` はエスケープしない。静的な CSS など信頼できる文字列のみ。
- void 要素（`meta`, `input`, `link`, `br`, `hr` など）は閉じタグを出さない。
- `ElementNode.Children` の中で `AttrNode` / `BoolAttrNode` は開始タグ内に、それ以外は中身として出力する。

### 6. SSR の流れ
- `http.ResponseWriter` は `io.Writer` を満たすので、`Render` に直接渡してストリーム出力する。
- `Content-Type: text/html; charset=utf-8` を必ずセットする。
- `render(w, node)` のようなラッパーを 1 つ用意し、`Renderer` の選択はアプリ全体で 1 箇所（`var renderer el.Renderer = el.HTMLRenderer{}`）に集約する。
- デバッグ時は `PlainRenderer{}` に差し替えるだけで中身を確認できる。

## アンチパターン（やらないこと）

- ❌ `Node` に `Render(w io.Writer)` を生やす（→ Renderer に分離する）
- ❌ `Div()`, `Class()` のような要素/属性ヘルパー関数を量産する（→ `const` のみ）
- ❌ `html/template` を混ぜる（→ エスケープは `Text()` が担う）
- ❌ 外部モジュール（gomponents 本体など）に依存する
- ❌ `Raw()` にユーザ入力を通す

## 拡張の方向性

- `If(cond, node)` / `Map(slice, fn)` のような合成ヘルパを `el` に追加。
- Pretty 出力 Renderer、属性フィルタ付きサニタイザ Renderer。
- `func(n Node) http.HandlerFunc` でハンドラ化する糖衣。
- `bytes.Buffer` に一度書いて `Content-Length` を付与する最適化。

## 一言でまとめると

> **Node はデータ、描画は Renderer。要素と属性は const。依存は標準ライブラリだけ。**
