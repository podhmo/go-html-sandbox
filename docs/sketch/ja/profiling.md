# 調査メモ: profiler で `pkg/el` と `pkg/tinymarkdown` のどこが重いか見る

`pkg/el` と `pkg/tinymarkdown` の速度を profiler で見て直す取り組みの記録。言語ごとに分けて書いている。対象はこの 2 つのパッケージだけで、ブログ全体や Workers の側（Static Assets、JSPI、アダプター）には広げていない。

- [Go 版](profiling-go.md): ベンチを足し、pprof で確保と走査を見て直した。API の変更込みの実験（`Inline` の構造体化、`el` のライターの変更）もここに追記している。
- MoonBit 版: これから。`profiling-moonbit.md` に、Go 版で効いたところをなぞった結果を書く。
