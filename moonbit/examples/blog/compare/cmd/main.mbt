///|
/// fetch gets url and keeps what the comparison looks at. Redirects are
/// not followed, so they compare as they are.
async fn fetch(url : String) -> @compare.Fetched {
  let (res, body) = @http.get(url)
  let content_type = res.headers
    .get(@http.CaseInsensitiveString("content-type"))
    .unwrap_or("")
  { status: res.code, content_type, body: body.text(), }
}

///|
/// try_fetch is fetch with the failure kept as data: compare reports why a
/// side failed instead of stopping.
async fn try_fetch(url : String) -> Result[@compare.Fetched, String] {
  Ok(fetch(url)) catch {
    e => Err(e.to_string())
  }
}

///|
/// main fetches each path from the Go blog and the MoonBit Worker, prints
/// a report per path and a summary, and fails when any path differs.
async fn main {
  let matches = @argparse.Command(
    "compare",
    about="Compare the Go blog and the MoonBit Worker path by path: status, Content-Type and body",
    options=[
      OptionArg(
        "lines",
        long="lines",
        about="show at most this many lines of each body diff",
        default_values=["40"],
      ),
    ],
    positionals=[
      PositionArg(
        "go",
        about="base URL of the Go blog, e.g. http://localhost:8080",
        num_args=@argparse.ValueRange::single(),
      ),
      PositionArg(
        "moonbit",
        about="base URL of the MoonBit Worker, e.g. http://localhost:8787",
        num_args=@argparse.ValueRange::single(),
      ),
      PositionArg(
        "path",
        about="paths to compare (default: /, a post, a document, /docs/, /favicon.svg and a missing path)",
        num_args=@argparse.ValueRange(lower=0),
      ),
    ],
  ).parse()
  guard matches.values is { "go": [go_base], "moonbit": [moonbit_base], .. } else {
    fail("need the base URLs of the Go blog and the MoonBit Worker")
  }
  let paths = match matches.values {
    { "path": [_, ..] as paths, .. } => paths
    _ => @compare.default_paths()
  }
  let max_lines = match matches.values {
    { "lines": [n], .. } => @string.parse_int(n)
    _ => 40
  }
  let reports = []
  for path in paths {
    let go = try_fetch(@compare.join_url(go_base, path~))
    let moonbit = try_fetch(@compare.join_url(moonbit_base, path~))
    let report = @compare.compare(path, go~, moonbit~, max_lines~)
    @stdio.stdout.write(report.text)
    reports.push(report)
  }
  let summary = @compare.summary(reports)
  @stdio.stdout.write(summary)
  if reports.any(r => !r.same) {
    fail(summary.trim_end())
  }
}
