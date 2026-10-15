///|
test "every post is embedded with its file name" {
  let names = @posts.files.iter().map(f => f.0).collect()
  let want = [
    "2026-10-14-hello.md", "2026-10-15-tinymarkdown.md", "2026-10-16-mobile-first.md",
    "2026-10-17-workers-wasm.md",
  ]
  for name in want {
    assert_true(names.contains(name), msg="missing \{name}")
  }
}

///|
test "files are sorted by name and hold the whole file" {
  let names = @posts.files.iter().map(f => f.0).collect()
  // String::compare puts shorter strings first; file names sort by
  // characters, as go:embed does.
  assert_eq(names, names.copy()..sort_by((a, b) => a.lexical_compare(b)))
  let hello = @posts.files.iter().find_first(f => f.0 == "2026-10-14-hello.md")
  guard hello is Some((_, content)) else { fail("no hello post") }
  assert_true(content.has_prefix("# Hello\n\n"))
  assert_true(content.has_suffix("embeds the posts with go:embed.\n"))
}

///|
test "non-ASCII text survives embedding" {
  let tiny = @posts.files
    .iter()
    .find_first(f => f.0 == "2026-10-15-tinymarkdown.md")
  guard tiny is Some((_, content)) else { fail("no tinymarkdown post") }
  assert_true(content.has_prefix("# tinymarkdown で書けること\n"))
}
