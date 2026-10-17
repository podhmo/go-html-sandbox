// Benchmarks for parse and inlines. The input is the largest Markdown file
// the repository embeds (docs/**/*.md and TODO.md, through
// examples/blog/repodocs), which is the heaviest page the blog parses; it
// stands in for a page when profiling parse and inlines, as go/pkg/
// tinymarkdown's BenchmarkParse and BenchmarkInlines do by reading the same
// files.

///|
/// largest_doc returns the largest embedded Markdown document.
fn largest_doc() -> String {
  let mut best = ""
  for (_, content) in @repodocs.files {
    if content.length() > best.length() {
      best = content
    }
  }
  best
}

///|
test (b : @bench.T) {
  let src = largest_doc()
  b.bench(name="parse", fn() { b.keep(@tinymarkdown.parse(src)) })
}

///|
test (b : @bench.T) {
  let src = largest_doc()
  b.bench(name="inlines", fn() { b.keep(@tinymarkdown.inlines(src)) })
}
