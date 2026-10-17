// Benchmarks for render_html. The input is the same tree shape as
// go/pkg/el's BenchmarkRenderHTML: an article page's worth of paragraphs, a
// nested list, and a table, which is what the renderer spends its time on.

///|
/// bench_page builds a tree shaped like an article page: paragraphs, a
/// nested list, and a table.
fn bench_page(paragraphs : Int32) -> @el.Node {
  let paras = []
  for i = 0; i < paragraphs; i = i + 1 {
    paras.push(
      @el.el(@el.p, [
        @el.Text("Text with <angle> brackets & ampersands, then "),
        @el.el(@el.code, [@el.Text("inline code")]),
        @el.Text(" and a "),
        @el.el(@el.a, [
          @el.Attr(@el.href, "/posts/a-post-with-a-longish-slug"),
          @el.Text("link"),
        ]),
        @el.Text(" to another page."),
      ]),
    )
  }
  let items = []
  for i = 0; i < 20; i = i + 1 {
    items.push(
      @el.el(@el.li, [
        @el.el(@el.a, [
          @el.Attr(@el.href, "/docs/ja/design"),
          @el.Text("a document"),
        ]),
        @el.Text(" item "),
        @el.el(@el.code, [@el.Text("code")]),
      ]),
    )
    if i % 5 == 0 {
      items.push(
        @el.el(@el.ul, [
          @el.el(@el.li, [@el.Text("nested")]),
          @el.el(@el.li, [@el.Text("items")]),
        ]),
      )
    }
  }
  let rows = []
  for i = 0; i < 20; i = i + 1 {
    rows.push(
      @el.el(@el.tr, [
        @el.el(@el.td, [@el.Text("cell with & and <")]),
        @el.el(@el.td, [@el.el(@el.code, [@el.Text("0.4 ms")])]),
      ]),
    )
  }
  @el.el(@el.article, [
    @el.el(@el.h1, [@el.Text("A page title")]),
    @el.el(@el.hgroup, paras),
    @el.el(@el.ul, items),
    @el.el(@el.table, [@el.el(@el.tbody, rows)]),
  ])
}

///|
test (b : @bench.T) {
  let page = bench_page(200)
  b.bench(name="render_html", fn() { b.keep(@el.render_html(page)) })
}
