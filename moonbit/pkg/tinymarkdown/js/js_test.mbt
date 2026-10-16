///|
extern "js" fn stringify(v : @js.Js) -> String = "(v) => JSON.stringify(v)"

///|
test "parse builds the TS port's Document" {
  inspect(
    stringify(
      @js.parse("# A\nb\n- x\n  - y\n> q\n\n| h |\n| - |\n| c |\n\n```\nz\n```"),
    ),
    content=(
      #|{"children":[{"kind":"section","level":1,"title":"A","children":[{"kind":"paragraph","text":"b"},{"kind":"list","items":[{"text":"x","children":[{"text":"y","children":[]}]}]},{"kind":"quote","children":[{"kind":"paragraph","text":"q"}]},{"kind":"table","header":["h"],"rows":[["c"]]},{"kind":"code","code":"z"}]}]}
    ),
  )
}

///|
test "inlines builds the TS port's Inline[]" {
  inspect(
    stringify(@js.inlines("a `b` [c `d`](/e)")),
    content=(
      #|[{"kind":"text","text":"a "},{"kind":"code","text":"b"},{"kind":"text","text":" "},{"kind":"link","children":[{"kind":"text","text":"c "},{"kind":"code","text":"d"}],"url":"/e"}]
    ),
  )
}
