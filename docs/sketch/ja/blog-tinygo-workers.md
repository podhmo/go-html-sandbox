# 実験レポート: `examples/blog` を TinyGo で Cloudflare Workers に載せる

TODO.md の「Run `examples/blog` on Cloudflare Workers with TinyGo」の spike。
マージするかは未定なので、2 つの方式をそれぞれ別ブランチで試した。

| ブランチ | 方式 |
| --- | --- |
| `spike/tinygo-workers` | 案 A: ビルドタグでエントリポイントを分ける（同じモジュール） |
| `spike/tinygo-workers-module` | 案 B: Workers 用のエントリポイントを別モジュールにする（案 A の上に積んである） |

## 結論

- TinyGo 0.43.0 + [syumai/workers-go](https://github.com/syumai/workers-go) v0.36.0 で、`examples/blog` は `wrangler dev` 上で動いた。記事一覧、記事、ドキュメント、favicon、404 がすべて期待どおりに返る。
- `pkg/*` と `go:embed` は TinyGo でそのまま動く。
- ただし「`main.go` だけをビルドタグで分ける」だけでは足りない。次の 2 点で、エントリポイント以外にも手を入れる必要があった。
  - TinyGo には `os.OpenRoot` がない。`-debug` 用の `repo.go` も TinyGo のビルドから外す必要がある。
  - **TinyGo の `net/http.ServeMux` は Go 1.22 より前の実装のまま**で、`GET /...`（メソッド指定）、`{$}`、`{name...}` に対応していない。全ページが 404 になったため、ルーティングを手書きにした（両案に共通）。
- 推奨は **案 B（モジュール分割）**。ルートの `go.mod` を依存なしのまま保てて、共有部分を `tinygo test` でテストできる。実際、ServeMux の差異は `tinygo test` で 10 件のテスト失敗として検出できた。案 A では、この種の差異をテストで捕まえる手段がない。
- 別モジュールは兄弟の `examples/blog-tiny` ではなく、入れ子の `examples/blog/workers` にするのがよい。理由は後述。

## 環境

| | バージョン |
| --- | --- |
| Go | 1.27.1（ホスト） |
| TinyGo | 0.43.0（Docker イメージ `tinygo/tinygo:0.43.0`。中の Go は 1.27.2、LLVM 22.1.4） |
| workers-go | v0.36.0。v0.35.0 で `github.com/syumai/workers` から `github.com/syumai/workers-go` に改名された（旧パスは deprecated な転送モジュール） |
| wrangler | 4.147.0（`npx wrangler@4`）。ローカルの `wrangler dev` だけで確認し、デプロイはしていない |

TinyGo はホストに入れず、リポジトリをマウントして Docker で動かすシム（`tinygo` という名前のシェルスクリプト）を `PATH` に置いて使った。`wrangler.jsonc` のビルドコマンドも、このシム経由で動くことを確認した。

## 確認したこと

### `pkg/*` と `go:embed`

- `tinygo test ./pkg/...` は 4 パッケージとも成功した。
- `go:embed` は、`examples/blog` の記事・favicon も、ルートパッケージの `sandbox.Docs`（`TODO.md` と `docs/`）も、TinyGo の wasm でそのまま読めた（`/docs/TODO` などが表示される）。

### そのままではビルドできない: `os.OpenRoot`

```
examples/blog/repo.go:37:15: undefined: os.OpenRoot
```

`-debug` でファイルを読むときの `os.Root` が TinyGo にはない。Workers には関係のない機能なので、Workers 用のビルドから外す。

### TinyGo の `ServeMux` は古い

TinyGo の `net/http` は標準ライブラリの複製に手を入れたもので、`ServeMux` は Go 1.22 より前の実装に、`{x}` だけを扱う独自のマッチを足したものだった。同じパターンを登録したときの結果:

| パターン | リクエスト | Go | TinyGo |
| --- | --- | --- | --- |
| `GET /get/{x}` | `GET /get/1` | 200 | 404 |
| `/wild/{x}` | `GET /wild/2` | 200 | 200 |
| `/exact/{$}` | `GET /exact/` | 200 | 404 |
| `POST /post` | `POST /post` | 200 | 404 |
| `GET /` と `/exact/{$}` を両方登録 | — | 登録時に panic（衝突） | panic しない |

`examples/blog` は `GET /{$}`、`GET /posts/{slug}`、`GET /docs/{path...}` を使っていたので、全ページが 404 になった。

対応として、`ServeMux` をやめて `server.route` で手書きで振り分けるようにした。パスの値は `r.SetPathValue` で入れるので、各ハンドラは変えずに済む。`ServeMux` がしていた次の挙動も合わせて実装し、テストを足した。

- GET と HEAD 以外は 404 ページ（以前も `/` のパターンが拾って 404 になっていた）
- `/docs` → `/docs/` へのリダイレクト
- `.`、`..`、連続するスラッシュを含むパスを、正規化したパスへリダイレクト（307）

標準 Go のビルドでは `ServeMux` のまま、TinyGo のビルドだけ手書きにする案もあるが、ルーティングが二重になるので採らなかった。

### workers-go の実行モデル

`workers-assets-gen` が生成する `worker.mjs` は、**リクエストのたびに新しい Wasm インスタンスを作って `main` を実行する**。そのため次のことが言える。

- 記事とドキュメントの読み込み（Markdown のパース）も、リクエストごとに毎回走る。`sync.Once` などでキャッシュしても効かない。
- 環境変数（`cloudflare.Getenv`）は `main` の中から読める。`-base-url` の代わりに、`wrangler.jsonc` の `vars.BASE_URL` から読むようにした。

ローカルの `wrangler dev` での応答時間は、TinyGo で 3〜10ms、標準 Go で 5〜8ms ほどだった。本番の CPU 時間の上限に対してどうかは未確認。

### バイナリサイズと Workers のサイズ制限

| ビルド | 生のサイズ | gzip -9 |
| --- | --- | --- |
| TinyGo（`-target wasm -no-debug`） | 2,092,466 B（2.0 MiB） | 741,246 B |
| 標準 Go（`GOOS=js GOARCH=wasm`） | 8,560,688 B（8.2 MiB） | 2,327,300 B |
| 標準 Go（`-ldflags='-s -w'`） | 8,324,183 B | 2,269,595 B |

2026-09-04 の [changelog](https://developers.cloudflare.com/changelog/post/2026-09-04-increased-worker-size-limit/) で、Workers のサイズ制限は「非圧縮で 64 MiB（全プラン共通）、圧縮後のサイズは無制限」になった（以前は圧縮後で Free 3 MB、Paid 10 MB）。標準 Go のビルドも十分に収まるので、**サイズはもう TinyGo を選ぶ決め手にならない**。標準 Go の wasm も `wrangler dev` で同じように動いた。

このため、ビルドタグは `tinygo` ではなく `js && wasm` にした。TinyGo の `-target wasm` は `GOOS=js GOARCH=wasm` になるので、どちらのコンパイラでも同じファイルが選ばれる。

### テスト

- 標準 Go の `go test` は、どちらの案でも今までどおり通る。
- `GOOS=js GOARCH=wasm go test`（node で実行）は、workers-go を import したパッケージでは失敗する。workers-go の `init` が Workers の JS グローバルを参照して panic するため。
- `tinygo test -target wasm` は、TinyGo の Docker イメージに node がないため試していない。
- native の `tinygo test` では、`httptest.NewServer` に接続できず（`connection refused`）、`Close` で止まった。この現象が出るのは `-watch` の SSE テスト（`TestLiveReloadEvents`）だけで、TinyGo では skip するようにした（案 B）。

## 案 A: ビルドタグ（`spike/tinygo-workers`）

```
examples/blog/
  main.go           //go:build !(js && wasm)   フラグ、-debug、-watch
  repo.go           //go:build !(js && wasm)   os.OpenRoot を使う
  repo_test.go      //go:build !(js && wasm)
  main_workers.go   //go:build js && wasm      workers.Serve
  content.go        記事と favicon の go:embed（両方のエントリポイントで共有）
  wrangler.jsonc
  ...その他は変更なし（server.go のルーティングだけ手書きに）
```

- 差分は小さい（12 ファイル、+198/-26。README を含む）。ディレクトリ構成も変わらない。
- 理想の「`main.go` だけを分岐」に近いが、`repo.go` と `repo_test.go` にもタグが要る（`repo.go` の中身を `main.go` に寄せれば、タグを付けるのは `main.go` とテストだけにできる）。
- ルートの `go.mod` に `github.com/syumai/workers-go` が入り、`go.sum` もできる。`go mod tidy` はすべてのビルドタグを見るので、この依存は消せない。標準 Go の native ビルドには workers-go はリンクされない（`go list -deps` で確認）。ただし「依存は標準ライブラリのみ」というリポジトリの方針から見ると、モジュールの依存グラフには載ってしまう。
- Workers 用のビルドに対して動くテストがない。native の `tinygo test` は `main.go` が `os.OpenRoot` を使うのでビルドできず、js/wasm の `go test` は workers-go の `init` で落ちる。ServeMux のような TinyGo 固有の差異は、`wrangler dev` で手で確かめるまで分からない。

## 案 B: モジュール分割（`spike/tinygo-workers-module`）

```
go.mod                         依存なしのまま
examples/blog/
  main.go, repo.go             標準の HTTP サーバー（タグなし）
  posts/
    embed.go                   package posts: //go:embed *.md
    *.md
  internal/site/               サーバー、ビュー、記事とドキュメントの読み込み、-watch
    content.go                 favicon の go:embed、EmbeddedSources
  workers/                     別モジュール
    go.mod                     require go-html-sandbox v0.0.0 + replace ../../..、workers-go
    main.go                    workers.Serve
    wrangler.jsonc
```

- ルートの `go.mod` は依存なしのまま。workers-go に依存するのは `examples/blog/workers` だけ。
- `go test ./...` をルートで実行しても、入れ子のモジュールは対象にならない。Workers 用は `cd examples/blog/workers` で別に扱う。
- `internal/site` は `os.OpenRoot` を使わないので、**native の `tinygo test ./examples/blog/internal/site` が通る**。試しにルーティングを ServeMux に戻すと、`go test` は通り、`tinygo test` は 10 件失敗した。TinyGo 固有の差異を CI で捕まえられる。
- `internal` の import 制限はパスで判定されるので、別モジュールの `examples/blog/workers` からでも `examples/blog/internal/site` を import できた。
- 記事はディレクトリをそのままにして、`posts/embed.go` でパッケージにした。`go:embed` は親ディレクトリを参照できないので、別モジュール（や別パッケージ）から記事を使うにはこの形が要る。`-debug` は今までどおり `examples/blog/posts` を読み、`embed.go` は `*.md` の glob に掛からないので問題ない。
- 代償は差分の大きさ（20 ファイル、+295/-105。ほとんどはファイルの移動と識別子の export）。`Post`、`Doc`、`LoadPosts`、`LoadDocs`、`NewServer`、`Server`、`Server.EnableLiveReload`、`Server.Watch`、`Source{FS, Paths}`、`DocSources`、`EmbeddedSources` を export した。

### `replace` ではなく `go.work` を使う場合

`examples/blog/workers/go.mod` の `require` + `replace ../../..` の代わりに、ルートに `go.work`（`use .` と `use ./examples/blog/workers`）を置く形も試した。

- `go.work` があれば、`workers/go.mod` からルートモジュールの `require` を消しても、`go build` と `tinygo build` の両方が通る。ルートで `go test ./...`／`go vet ./...` を実行しても、`workers` のパッケージは対象にならない（`go list ./...` で確認）。
- `require` を残して `replace` だけを消すと、`go.work` があっても `v0.0.0` を取りに行って失敗した。
- `go.work` がないとき（`GOWORK=off`、または clone した直後）はビルドできない。`.gitignore` が `go.work` を無視しているので、コミットしない運用とは合わない。
- `go mod tidy` は `go.work` を見ないので、`workers` で実行すると proxy から公開済みのルートモジュールを取ってきて、`internal/site` がないと言って失敗する。

このため `replace` を残すのがよい。`replace` があれば、モジュール単体で `go mod tidy` もビルドも完結する。エディタ（gopls）で両方のモジュールをまとめて開きたいときに、各自が手元で `go.work` を作る（ignore されたまま）のは、`replace` と併用しても問題ない。

### `examples/blog-tiny`（兄弟）ではなく `examples/blog/workers`（入れ子）にする理由

- 兄弟の `examples/blog-tiny` からは `examples/blog/internal/...` を import できない。共有部分を `examples/internal/...` に移すか、`internal` でない公開パッケージにする必要がある。入れ子にすれば、ブログに関係するものを `examples/blog` の下にまとめたまま `internal` を使える。
- `-watch` や `-debug` などのフラグは Workers 側には要らない。この「フラグなしの別エントリポイント」という性格は、どちらに置いても同じ。
- 名前を `tiny` にしなかったのは、上で書いたとおり標準 Go でもビルドできて、TinyGo 専用ではないから。中身を表すのは「Workers で動かす」こと。

## 比較

| | 案 A: ビルドタグ | 案 B: 別モジュール |
| --- | --- | --- |
| ルートの `go.mod` | workers-go が入る | 依存なしのまま |
| 変更の大きさ | 小（タグ 3 ファイルと `content.go`） | 中（共有部分を `internal/site` に移動、export） |
| TinyGo でのテスト | できない | `tinygo test ./examples/blog/internal/site` |
| ディレクトリ構成 | 変わらない | `internal/site`、`posts/embed.go`、`workers/` が増える |
| `go test ./...` | 今までどおり | 今までどおり（`workers/` は対象外） |
| ビルドの切り替え | `GOOS`/`GOARCH`（`-target wasm`） | ディレクトリ（`cd examples/blog/workers`） |

両案に共通の変更: ルーティングの手書き化（とリダイレクトの再実装）、`BASE_URL` を `wrangler.jsonc` から読むこと。

## 未確認・残課題

- 本番の Cloudflare へのデプロイ（`wrangler deploy`）。リクエストごとに全記事をパースする実行モデルで、CPU 時間の上限に収まるか。
- 記事が増えたときのリクエストごとのコスト。必要なら、パース結果をビルド時に生成する、ルートに必要な記事だけを読む、などを考える。
- `tinygo test -target wasm`（node が必要）での実行。
- `HEAD` には GET と同じ本文を返している（以前の ServeMux 経由の挙動と同じで、`net/http` のサーバーが本文を捨てる）。Workers 上で HEAD がどう扱われるかは未確認。
