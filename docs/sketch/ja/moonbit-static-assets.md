# 調査レポート: MoonBit 版のブログの文章を Wasm の外に出す

TODO.md の「MoonBit 版のブログで、記事や文書を足しても Wasm が太らないようにする」の調査。
今の MoonBit 版は、記事、`TODO.md`、`docs/**/*.md` を Wasm に埋め込んでいるので、書くたびに Wasm が大きくなる。
`wrangler deploy` と `make dev` だけで済む今の手軽さを保ったまま、文章を Wasm の外に出す方法を調べ、`/tmp` の小さな spike で確かめた。
実装はまだしていない。

## 結論

- **Workers の Static Assets を使う。** `wrangler.jsonc` に `assets` を書くだけで、同じ `wrangler deploy` で文章がアップロードされ、`wrangler dev` でもそのまま動く。R2 や KV のような別の作成やアップロードの手順は要らない。アセットへのリクエストと保存に料金はかからない。
- **Total Upload（Worker の大きさ）にはアセットが入らない。** spike では 11 ファイルのアセットを置いても、Total Upload は Worker の JS の 1.02 KiB だけだった。
- **`run_worker_first: true` にすれば、今のルーティングは何も変わらない。** すべてのリクエストが今までどおり Worker に届き、Worker は binding（`env.ASSETS.fetch()`）でだけ文章を読む。`/posts/hello.md` のようなパスに、アセットがそのまま返ることはない。
- **最初の一歩は「Worker の起動後の最初のリクエストで、全部の文章を取って Wasm に渡す」でよい。** Wasm の中は今と同じく同期のまま、埋め込みの代わりに受け取ったファイルから `Site` を作る。目録はファイル名の一覧だけなので、シェルで作れる。リクエストごとに必要なファイルだけを取る形は、文章がずっと増えてから考える。
- 埋め込みをやめると、Wasm は約 249 KB から 100 KB 強になる見込み（埋め込んだ文章が約 134 KB）。記事を足しても Wasm は変わらない。

## 今の大きさ

2026-10-15 の main（記事 5 本）で測った。

| もの | 大きさ |
| --- | --- |
| Wasm（`moon build --target wasm-gc --release`） | 249,111 B |
| 記事（`go/examples/blog/posts/*.md`）の合計 | 12,929 B |
| `TODO.md` と `docs/**/*.md` の合計 | 120,932 B |
| 生成した `posts/embedded.mbt` / `repodocs/embedded.mbt` / `assets/embedded.mbt` | 14,480 B / 136,193 B / 3,300 B |
| wrangler の Total Upload | 244.97 KiB（gzip 後 80.58 KiB） |

太る原因は、記事よりも文書（特に `docs/sketch/ja/` のレポート）のほうが大きい。

## 候補

| 方法 | 手軽さ | Wasm の大きさ | 備考 |
| --- | --- | --- | --- |
| 今のまま埋め込む | 最も手軽 | 文章に比例して増える | 64 MiB の上限まではまだ遠い |
| Static Assets | `wrangler.jsonc` に数行。デプロイの手順は同じ | 文章に関係なく一定 | 第一候補 |
| R2 | バケットの作成と、文章のアップロードの手順が別に要る | 一定 | デプロイと文章の更新が別々になる。`wrangler dev` では別のローカルのバケットになる |
| KV | R2 と同じく、別に書き込む手順が要る | 一定 | 結果整合なので、デプロイ直後に古い文章が見えうる |
| 文章を圧縮して埋め込む | 手軽 | 増え方が緩やかになるだけ | 展開のコードが要る。`DecompressionStream` は JS の側にしかない |
| ビルド時にすべてのページを HTML にする | Static Assets と同じ | Wasm がリクエスト時に要らなくなる | Wasm で動かすというこのブログの目的から外れる |

## Static Assets について確かめたこと

### ドキュメント

[Static Assets](https://developers.cloudflare.com/workers/static-assets/)、[binding](https://developers.cloudflare.com/workers/static-assets/binding/)、[料金と制限](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)、[Workers の制限](https://developers.cloudflare.com/workers/platform/limits/) を読んだ。

- `assets` の設定は `directory`（置き場所）、`binding`（Worker から読むための名前。例は `ASSETS`）、`run_worker_first`。
- 既定（`run_worker_first: false`）では、パスがアセットに一致すると Worker を通さずにそのまま返す。`true` にするとすべてのリクエストが先に Worker に届く。パターンの配列で一部のパスだけにもできる。
- `env.ASSETS.fetch()` は Request、URL、文字列を受け取り、URL のホスト名は無視してパスだけで探す。
- 料金: 「Requests to static assets are free and unlimited」「There is no additional cost for storing Assets」。Worker を通るリクエストは今までどおり Workers の料金で数える。無料プランの上限を超えると、`run_worker_first` に一致するリクエストは 429 になる（今も全リクエストが Worker を通るので、条件は変わらない）。
- 制限: アセットのファイル数は Free で 20,000、Paid で 100,000。1 ファイルは 25 MiB まで。Worker 本体は非圧縮で 64 MiB まで。起動（グローバルスコープの評価）は 1 秒まで。
- アップロードしないファイルは、アセットのディレクトリの `.assetsignore`（`.gitignore` と同じ書き方）で指定できる。

### spike

`/tmp` に、記事 5 本と `docs/sketch/ja/*.md` 6 本を `content/` に置き、次の設定で確かめた（wrangler 4.148.0）。

```jsonc
{
  "name": "assets-spike",
  "main": "./worker.mjs",
  "compatibility_date": "2026-10-01",
  "assets": { "directory": "./content", "binding": "ASSETS", "run_worker_first": true }
}
```

`/raw/<path>` で `env.ASSETS.fetch(new URL(path, "https://assets.local"))` の結果を返し、`/many` で記事 5 本を `Promise.all` でまとめて取る Worker を書いた。

| 確かめたこと | 結果 |
| --- | --- |
| `wrangler deploy --dry-run` | `Read 11 files from the assets directory`、Total Upload は 1.02 KiB / gzip 0.50 KiB。アセットは含まれない |
| `/posts/2026-10-14-hello.md` を直接取る | Worker の応答が返った（`run_worker_first: true` が効いている） |
| binding で `.md` を取る | 200、`Content-Type: text/markdown; charset=utf-8`、本文はファイルのまま |
| 拡張子なしのパス、存在しないファイル | どちらも 404。`html_handling` は `.html` だけが対象で、`.md` が別名で見つかることはない |
| `wrangler dev` に 20 回の往復の中央値 | 何も取らない `/` が 1.1 ms、23 KB の文書を 1 つ取ると 1.5 ms、記事 5 本を並行して取ると 1.8 ms |

ローカルの workerd での数字なので、本番の速さはデプロイしてから測る必要がある。

## 設計の案

### 文章の置き場所

`moonbit/workers/build/` は、今も Wasm をコピーする、git で無視している置き場所になっている。ビルドのコマンドで、ここに `content/` を作って文章をコピーする。

- `content/posts/*.md`（`go/examples/blog/posts` から）
- `content/docs/TODO.md` と `content/docs/docs/**/*.md`（リポジトリから。パスは今の `repodocs` と同じ）
- `content/files.txt`: 上のファイルのパスの一覧（目録）

Static Assets には一覧を返す API がないので、目録は自分で作る。`find` と `sort` で足りる。`site.css` と `favicon.svg` は小さく、記事とともに増えるものでもないので、埋め込んだままでよい。

Go 版は今までどおり `go:embed` で埋め込む。変わるのは MoonBit 版だけ。

### Wasm への渡し方

今の `serve` は同期で、`worker.mjs` からパスを受け取ってその場で応答を作る。`env.ASSETS.fetch()` は非同期なので、Wasm から直接は呼べない。案は 3 つある。

1. **最初のリクエストで全部を渡す（推奨）**: Worker の起動後の最初のリクエストで、`worker.mjs` が `files.txt` とすべてのファイルを並行して取り、ファイル名と本文を順に Wasm に渡す（今の `path_push` と同じコード単位の受け渡しに、`file_name` と `file_body` のような export を足す）。Wasm はそれで `Site` を作り、以降は今と同じく同期で応答する。
   - 今の `Site::embedded` は、埋め込んだファイルから最初の `serve` で `Site` を作っているので、その入力を差し替えるだけで済む。記事のリンクを解決するのに全部の文書の一覧が要る、という今の作りもそのまま使える。
   - 代償は、Worker の起動後の最初のリクエストだけが、全部の文章を取る分だけ遅くなること。今の量（約 134 KB）なら、spike の数字から数 ms と見込む。isolate のメモリにも全文が載るが、これは今と同じ。
2. **JS がパスから要るファイルを決めて先に取る**: リクエストごとに 1 ファイルだけ取ればよいが、ルーティングの知識が `worker.mjs` に漏れる。一覧ページやリンクの解決には、結局全部の一覧と各記事の title / description が要る。
3. **Wasm が要るファイルを返し、JS が取って呼び直す**: ルーティングは Wasm に残るが、ABI が「応答」か「このファイルが要る」の 2 通りを返すようになる。一覧ページのために、title と description をビルド時に目録に入れておく必要もある（Go 版と同じ規則で作るには、`tinyfrontmatter` と `tinymarkdown` を使う native のコマンドが要る）。

1 は ABI に入力の export を足すだけで、Wasm の中のルーティングもレンダリングもそのまま使える。3 は、文章が数 MB になって最初のリクエストの遅れが気になってきたら考える。そのときは TODO.md の Future work の「Workers 用アダプターを最適な形に磨く」と一緒に設計する。

### 変わらないこと、変わること

- `make dev` と `make deploy` の使い方は変わらない。`wrangler dev` の `watch_dir` には、すでに記事と `docs/` が入っている。
- `make test` は、テスト用の文章を `Site` に直接渡すので、ネットワークも Assets も要らない。埋め込みは、テストの中で全部の文章がそろっていることを確かめる用途にだけ残すか、やめる。
- 比較（`make compare`）は今までどおり、Go 版と一致することを確かめる物差しになる。

## 未確認

- 本番での、Worker の起動後の最初のリクエストの遅れ。
- `wrangler dev` で、アセットのディレクトリの中身がビルドで書き換わったときに、再起動なしで新しい文章が見えるか。
- アセットのファイル名に日本語などが入ったときの扱い（今の文章のファイル名は ASCII だけ）。
