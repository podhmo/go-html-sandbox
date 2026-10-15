# TODO

> **このファイルの更新について:** 運用ルールは
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) にある。
> タスクを追加・完了するときは必ずそれに従う。要点: このファイルには着手できる
> 作業だけを書く（`[ ]` / `[-]`）。終わった作業は `[x]` にし、定期的な GC で
> `TODO-archive.md` に移す。

このファイルは着手できるタスクだけを管理する。完了した作業は、定期的な GC で
`TODO-archive.md` に移す。

## To Be Implemented

### Future work

- [ ] **MoonBit の Workers 用アダプターを必要十分な形に磨く**: 今のアダプター
  （`moonbit/workers/worker.mjs` と `moonbit/worker` の export、host の
  import）は、spike から必要に応じて継ぎ足してきたもの。これまでの知見を総動員し、
  ブログが今使っている範囲で過不足のない形に設計し直す。知見とは、Workers では
  `use-js-builtin-string` が使えないこと、コード単位の受け渡しが時間の約 8 割を
  占めること、`wasm-opt -Oz` の効果、workerd による URL の正規化、メソッドと HEAD
  の扱い、`set_query` と `set_base_url` を後から足した経緯など。
  - 受け渡しの方法（コード単位ごと、またはまとめて渡す）と export / import の数、
    `worker.mjs` の行数、Wasm のサイズ、起動時間、いちばん大きいページの処理時間を
    今と比べる。
  - 完了の条件: `make compare` で Go 版と一致したまま、結果を
    [調査メモ](docs/sketch/ja/moonbit-workers-wasm.md)に記録する。

