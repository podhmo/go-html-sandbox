// The first Wasm again, linked to the second: it imports render from the
// module "html", which the host fills with ../html's exports, and calls it
// directly, with no JS in between.

///|
fn render(json : String) -> String = "html" "render"

///|
/// preview parses md and renders it through the imported render.
pub fn preview(md : String) -> String {
  render(@parser.parse(md))
}
