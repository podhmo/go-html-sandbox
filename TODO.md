# TODO

> **このファイルの更新について:** 運用ルールは
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) にある。
> タスクを追加・完了するときは必ずそれに従う。要点: このファイルには着手できる
> 作業だけを書く（`[ ]` / `[-]`）。終わった作業は `[x]` にし、定期的な GC で
> `TODO-archive.md` に移す。

このファイルは着手できるタスクだけを管理する。完了した作業は、定期的な GC で
`TODO-archive.md` に移す。

## To Be Implemented

- [x] **MoonBit の Wasm バックエンドを Cloudflare Workers で試す**:
  ブログを移植する前に、ローカルで確認でき、デプロイもできる MoonBit の
  Worker を `moonbit/` に用意する。ページは `wasm-gc`（Workers ではコンパイル
  できない `use-js-builtin-string` は使わない）から、コード単位の ABI で返す。
  [調査メモ](docs/sketch/ja/moonbit-workers-wasm.md)を参照。
  - [x] **`moonbit/` の雛形**: トップページと 404 ページを組み立てる `render`
    を持つ MoonBit のモジュール（`moon.mod`、`moon.pkg`）と、その両方を確かめる
    `moon test`。完了の条件: `moon test` が通り、
    `moon build --target wasm-gc --release` でできる Wasm の export が
    `path_push` と `serve` だけ、import が `host.put` だけである。
  - [x] **Worker と `wrangler dev`**: spike の `worker.mjs` と、MoonBit を
    ビルドして Wasm を `worker.mjs` の隣にコピーする（git では無視する）
    `wrangler.jsonc` を `moonbit/workers/` に置く。完了の条件: そこで
    `npx wrangler dev` を実行するとトップページが表示され、`<` を含むパスが
    エスケープされる。
  - [x] **ABI でステータスとヘッダーを返す**: `serve` がステータスコードと
    content type を伝えられるようにし（例: `host.status(code)` と `host.header`
    の呼び出し）、存在しないパスに 404 を返す。完了の条件: `wrangler dev` に
    `curl -i` すると 200 / 404 と正しい `Content-Type` が返り、`render` が選ぶ
    ステータスを `moon test` で確かめている。
  - [x] **Makefile のターゲット**: `go/Makefile` と同じように、`build`、`test`、
    `dev`、`deploy` を持つ `moonbit/Makefile` を作る（ルートの `Makefile` は
    なく、各実装はそれぞれのディレクトリで実行する）。完了の条件: clone 直後の
    状態から、`moonbit/` で `make test dev` が動く。
  - [x] **デプロイ**: 当面は Worker `blog-moonbit` としてデプロイし、Go 版の
    `blog` は残す。最終的には、勝ったほうの実装を `blog` としてデプロイする。
    Go 版の Worker と同じ手順に従う。完了の条件: workers.dev の URL がトップ
    ページと 404 を返し、Workers が wasm-gc のアップロードを受け付けることを
    確かめる。wrangler が表示するアップロードサイズを調査メモに記録する。
  - [x] **計測**: `wasm-opt -Oz` をかけた Wasm のサイズと、約 50 KB のページで
    `serve` がコード単位ごとの呼び出しにかける時間（ローカルの `wrangler dev`
    で）を測る。両方を調査メモに記録し、呼び出しが遅ければ、UTF-8 のバイト列を
    線形メモリ越しに渡す ABI を検討する。

- [ ] **ブログを MoonBit で作り直す**: 同じサイトをトップレベルの `moonbit/`
  に作り、Wasm として Cloudflare Workers で動かして、Wasm のサイズを Go 版と
  比べる（TinyGo で約 2 MiB / gzip 後 760 KiB、標準 Go で約 8 MiB。
  [レポート](docs/sketch/ja/blog-tinygo-workers.md)を参照）。`pkg/*`（HTML
  ビルダー、Markdown パーサー）をどこまで移植するかを決め、比較の結果を
  `docs/` に記録する。下の各ステップは、`moonbit/` で `make test` と
  `make dev` で確認でき、`make deploy` でデプロイできる状態で終える。対象は
  Worker が配信するものだけで、`-debug` や `-watch` は移植しない。
  [実験](docs/sketch/ja/moonbit-workers-wasm.md)の続き。
  - [ ] **Go 版のブログと比べる**: Go 版のブログ（`go run ./examples/blog`）と
    MoonBit の Worker（`make dev`）から同じパスを取得し、レスポンスごとに
    ステータス、`Content-Type`、本文の差分を取るスクリプトを `moonbit/` に
    置く。完了の条件: `/`、記事 1 つ、文書 1 つ、`/docs/`、`/favicon.svg`、
    存在しないパスに対して実行でき、どれが違うかを報告する（最初は全部違う）。
  - [ ] **記事と文書を埋め込む**: MoonBit には `go:embed` がない。moon の
    ビルド前処理（例: `:embed` コマンド）でファイルを MoonBit のソースに
    変換できるかを確かめ、できなければ、`make` と wrangler のビルドから実行
    するスクリプトで生成する。Go 版のブログの記事
    （`go/examples/blog/posts/*.md`）、`TODO.md`、`docs/**/*.md` を、ファイル
    パスと内容の組として使い、生成したソースはコミットしない。完了の条件:
    `moon test` ですべてがそろっていることを確かめ、clone 直後の状態から
    `make build` が通る。
  - [ ] **HTML ビルダー**: `pkg/el`（ノード、エスケープ、レンダリング）と、
    `pkg/picoel` のうちページで使う部分を移植する。完了の条件: Go のテストの
    うち当てはまるケースを `moon test` で、同じ出力で確かめている。
  - [ ] **front matter と Markdown**: `pkg/tinyfrontmatter` と
    `pkg/tinymarkdown`（`#####` までのセクション、リスト、段落、引用、
    フェンスで囲んだコード、表。インラインのコードとリンク）を移植する。
    完了の条件: Go のテストのケースを `moon test` で、同じ構文木で確かめて
    いる。
  - [ ] **記事**: 埋め込んだ記事（`YYYY-MM-DD-slug.md`。タイトルと説明は
    front matter、なければ最初の見出しと段落から）を読み込み、`/` と
    `/posts/{slug}` を Go 版のブログと同じレイアウト（pico.css、`BASE_URL`
    からの OGP タグ。`BASE_URL` は `wrangler.jsonc` から渡す）で返す。
    完了の条件: 比較スクリプトで、`/` とすべての記事が Go 版と一致する。
  - [ ] **文書とリンク**: `/docs/` と `/docs/{path}` を返し、Markdown の相対
    リンクを Go 版と同じように解決する（`/docs/` や `/posts/` のページへ、
    GitHub へ、またはリンクにしない）。完了の条件: 比較で、すべての文書が
    一致する。
  - [ ] **残りのルート**: `/favicon.svg`、`/site.css?v=<hash>`、記事と文書の
    `.md` 版、リダイレクト（正規化されていないパス、`/docs` から `/docs/`）、
    404 ページ。完了の条件: Go 版のブログのすべてのパスで、比較に差分がない。
  - [ ] **比較して記録する**: デプロイし、wrangler が表示するアップロード
    サイズと起動時間を、TinyGo 版と標準 Go 版の数字と並べて、いちばん大きい
    ページで `serve` にかかる時間とともに調査メモに記録する。どちらの実装を
    `blog` としてデプロイするかを決める。

### Future work

