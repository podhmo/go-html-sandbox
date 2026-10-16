# TODO

> **このファイルの更新について:** 運用ルールは
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) にある。
> タスクを追加・完了するときは必ずそれに従う。要点: このファイルには着手できる
> 作業だけを書く（`[ ]` / `[-]`）。終わった作業は `[x]` にし、定期的な GC で
> `TODO-archive.md` に移す。

このファイルは着手できるタスクだけを管理する。完了した作業は、定期的な GC で
`TODO-archive.md` に移す。

## To Be Implemented

- [ ] **MoonBit 版のブログで、記事や文書を足しても Wasm が太らないようにする**:
  今は記事、`TODO.md`、`docs/**/*.md` を Wasm に埋め込んでいるので、書くたびに
  Wasm が大きくなる（249 KB のうち、埋め込んだ文章が約 134 KB）。`wrangler deploy`
  と `make dev` だけで済む今の手軽さを保ったまま、文章を Wasm の外に出す。
  第一候補は Workers の Static Assets（`wrangler.jsonc` の `assets`。同じ
  `wrangler deploy` でアップロードされ、`wrangler dev` でも動き、R2 や KV のような
  別の手順が要らない）。Static Assets には一覧の API がないので、ファイルの一覧は
  ビルド時に作る。
  - 決めること: 文章を Wasm にどう渡すか（`serve` は同期なので、JS が先に取って
    渡すか、Wasm が要るファイルを返して呼び直すか）。下の Future work の
    アダプターの見直しと関わる。
  - [調査レポート](docs/sketch/ja/moonbit-static-assets.md)では、最初のリクエストで
    全部の文章を取って Wasm に渡す案を推している。
  - 完了の条件: `make compare` で Go 版と一致したまま、記事を 1 本足しても Wasm の
    サイズが変わらない。サイズと処理時間の変化を
    [調査メモ](docs/sketch/ja/moonbit-workers-wasm.md)に記録する。
- [x] **tinymarkdown: ネストした箇条書きを扱う**: ブログで `TODO.md` をそのまま
  読めるように、インデントした `- ` を親の項目の子のリストにする。今は
  `List.Items` が文字列の並びなので、子の項目が親と同じ階層に並んでしまう
  （`examples/parse-markdown` で確かめられる）。
  - [x] Go 版（`go/pkg/tinymarkdown`）を直し、HTML とプレーンテキストの描画も
    子のリストに対応させる。
  - [x] MoonBit 版（`moonbit/tinymarkdown`）も同じように直す。
  - 完了の条件: `TODO.md` の入れ子がそのまま描画され、`make compare` で Go 版と
    一致する。

### Future work

- [ ] **MoonBit の Workers 用アダプターを最適な形に磨く**: 今のアダプター
  （`moonbit/workers/worker.mjs` と `moonbit/worker` の export、host の
  import）は、ブログに必要十分で、足りないものはない。ただ、spike から必要に
  応じて継ぎ足してきたものなので、これまでの知見を総動員して最適な形に設計し
  直す。知見とは、Workers では
  `use-js-builtin-string` が使えないこと、コード単位の受け渡しが時間の約 8 割を
  占めること、`wasm-opt -Oz` の効果、workerd による URL の正規化、メソッドと HEAD
  の扱い、`set_query` と `set_base_url` を後から足した経緯など。
  - 受け渡しの方法（コード単位ごと、またはまとめて渡す）と export / import の数、
    `worker.mjs` の行数、Wasm のサイズ、起動時間、いちばん大きいページの処理時間を
    今と比べる。
  - 完了の条件: `make compare` で Go 版と一致したまま、結果を
    [調査メモ](docs/sketch/ja/moonbit-workers-wasm.md)に記録する。
  - 探索の記録は[探索メモ](docs/sketch/ja/moonbit-workers-adapter.md)にある。
    線形メモリに UTF-8 でまとめて渡す案、`moon-wasm-opt -Oz`、workerd の
    `wasm_esm_integration_builtins` フラグを使う案などを、一つずつ確かめる。

