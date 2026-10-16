///|
let site : @site.Site = @site.Site::embedded(
  base_url="https://blog.podhmo.workers.dev",
) catch {
  _ => panic()
}

///|
/// bench renders /, or the largest page when big is 1, and returns the
/// body's length, without sending anything to the host.
pub fn bench(big : Int32) -> Int32 {
  let p = if big == 1 { "/docs/sketch/ja/moonbit-modernize" } else { "/" }
  site.render(p).body.text().length()
}
