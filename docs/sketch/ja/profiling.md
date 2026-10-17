# 調査メモ: profiler で `pkg/el` と `pkg/tinymarkdown` のどこが重いか見る

`pkg/el` と `pkg/tinymarkdown` の速度を profiler で見て直す取り組みの記録。言語ごとに分けて書いている。対象はこの 2 つのパッケージだけで、ブログ全体や Workers の側（Static Assets、JSPI、アダプター）には広げていない。

- [Go 版](profiling-go.md): ベンチを足し、pprof で確保と走査を見て直した。API の変更込みの実験（`Inline` の構造体化、`el` のライターの変更）もここに追記している。
- [MoonBit 版](profiling-moonbit.md): `moon bench` で前後を取り、`perf` と `addr2line` で内訳を見た。Go 版で効いたところ（セル、インラインの走査、タグと属性の連結）をなぞり、行とセルを `StringView` のまま引き回した。
