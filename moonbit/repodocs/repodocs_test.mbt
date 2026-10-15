///|
test "TODO.md and the documents under docs/ are embedded by path" {
  let names = [ for (name, _) in @repodocs.files => name ]
  let want = [
    "TODO.md", "docs/ja/design.md", "docs/sketch/ja/blog.md", "docs/sketch/ja/moonbit-workers-wasm.md",
  ]
  for name in want {
    assert_true(names.contains(name), msg="missing \{name}")
  }
  for name in names {
    assert_true(
      name == "TODO.md" || (name.has_prefix("docs/") && name.has_suffix(".md")),
      msg="unexpected \{name}",
    )
  }
}

///|
test "files are sorted by path and hold the whole file" {
  let names = [ for (name, _) in @repodocs.files => name ]
  assert_eq(names, names.copy()..sort_by((a, b) => a.lexical_compare(b)))
  let todo = @repodocs.files.iter().find_first(f => f.0 == "TODO.md")
  guard todo is Some((_, content)) else { fail("no TODO.md") }
  assert_true(content.has_prefix("# TODO\n"))
  assert_true(content.contains("## To Be Implemented"))
}
