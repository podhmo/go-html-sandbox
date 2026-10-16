// tinymarkdown for the ts blog (../../../../ts): parse and inlines, built
// for the js target, returning plain JS objects in the shape of the types
// in ts/pkg/tinymarkdown/tinymarkdown.ts. `make ts` copies the build there.

///|
/// Js is a JS value: what parse and inlines return.
#external
pub type Js

///|
extern "js" fn new_object() -> Js = "() => ({})"

///|
extern "js" fn new_array() -> Js = "() => []"

///|
extern "js" fn set(obj : Js, key : String, value : Js) -> Unit = "(o, k, v) => { o[k] = v; }"

///|
extern "js" fn push(arr : Js, value : Js) -> Unit = "(a, v) => { a.push(v); }"

///|
extern "js" fn of_string(s : String) -> Js = "(s) => s"

///|
extern "js" fn of_int(n : Int32) -> Js = "(n) => n"

///|
fn[T] array(xs : Array[T], f : (T) -> Js) -> Js {
  let a = new_array()
  for x in xs {
    push(a, f(x))
  }
  a
}

///|
fn strings(xs : Array[String]) -> Js {
  array(xs, of_string)
}

///|
fn object(kind : String, fields : Array[(String, Js)]) -> Js {
  let o = new_object()
  set(o, "kind", of_string(kind))
  for field in fields {
    set(o, field.0, field.1)
  }
  o
}

///|
/// parse is tinymarkdown's parse, returning a Document of the TS port.
pub fn parse(src : String) -> Js {
  let o = new_object()
  set(o, "children", blocks(@tinymarkdown.parse(src).children))
  o
}

///|
fn blocks(bs : Array[@tinymarkdown.Block]) -> Js {
  array(bs, b => {
    match b {
      Section(level~, title~, children~) =>
        object("section", [
          ("level", of_int(level)),
          ("title", of_string(title)),
          ("children", blocks(children)),
        ])
      Paragraph(text) => object("paragraph", [("text", of_string(text))])
      List(items) => object("list", [("items", list_items(items))])
      Quote(children) => object("quote", [("children", blocks(children))])
      Table(header~, rows~) =>
        object("table", [
          ("header", strings(header)),
          ("rows", array(rows, strings)),
        ])
      CodeBlock(code) => object("code", [("code", of_string(code))])
    }
  })
}

///|
fn list_items(items : Array[@tinymarkdown.Item]) -> Js {
  array(items, it => {
    let o = new_object()
    set(o, "text", of_string(it.text))
    set(o, "children", list_items(it.children))
    o
  })
}

///|
/// inlines is tinymarkdown's inlines, returning the Inline[] of the TS port.
pub fn inlines(s : String) -> Js {
  inline_array(@tinymarkdown.inlines(s))
}

///|
fn inline_array(xs : Array[@tinymarkdown.Inline]) -> Js {
  array(xs, i => {
    match i {
      Text(t) => object("text", [("text", of_string(t))])
      Code(t) => object("code", [("text", of_string(t))])
      Link(children~, url~) =>
        object("link", [
          ("children", inline_array(children)),
          ("url", of_string(url)),
        ])
    }
  })
}
