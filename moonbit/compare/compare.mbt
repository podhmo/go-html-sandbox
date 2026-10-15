///|
/// Fetched is what a server answered for one path.
pub(all) struct Fetched {
  status : Int32
  content_type : String
  body : String
}

///|
/// default_paths are the paths compared when none are given: the top
/// page, a post, a document, the document index, the favicon, and a path
/// that exists on neither side.
pub fn default_paths() -> Array[String] {
  [
    "/", "/posts/hello", "/docs/ja/design", "/docs/", "/favicon.svg", "/no-such-page",
  ]
}

///|
/// join_url appends path to base, dropping the slashes at the end of base
/// so that both "http://h:1" and "http://h:1/" work.
pub fn join_url(base : String, path : String) -> String {
  let mut end = base.length()
  while end > 0 && base.code_unit_at(end - 1) == '/' {
    end -= 1
  }
  base.view(end_offset=end).to_owned() + path
}

///|
/// segments splits body into the units the body diff works on: a segment
/// ends after each newline and after each '>'. The Go blog writes most of
/// a page on one line, so lines alone would make the whole page one change.
fn segments(body : String) -> Array[String] {
  let out = []
  let sb = StringBuilder()
  for c in body {
    sb.write_char(c)
    if c == '\n' || c == '>' {
      out.push(sb.to_string())
      sb.reset()
    }
  }
  if sb.to_string() != "" {
    out.push(sb.to_string())
  }
  out
}

///|
/// show_segment makes a segment fit on one line of the report.
fn show_segment(s : String) -> String {
  let sb = StringBuilder()
  for c in s {
    match c {
      '\n' => sb.write_string("\\n")
      '\r' => sb.write_string("\\r")
      '\t' => sb.write_string("\\t")
      _ => sb.write_char(c)
    }
  }
  sb.to_string()
}

///|
/// body_diff returns a unified diff from go to moonbit, split into
/// segments, cut after max_lines lines.
pub fn body_diff(
  go : String,
  moonbit : String,
  max_lines~ : Int32 = 40,
) -> String {
  let d = @diff.Diff(old=segments(go)[:], new=segments(moonbit)[:])
  let lines = []
  for h in d.group(context=2) {
    for line in h.render(show=show_segment).split("\n") {
      if line != "" {
        lines.push(line.to_owned())
      }
    }
  }
  let sb = StringBuilder()
  sb.write_string("--- go\n+++ moonbit\n")
  for i, line in lines {
    if i >= max_lines {
      sb.write_string("... \{lines.length() - max_lines} more lines\n")
      break
    }
    sb.write_string(line)
    sb.write_char('\n')
  }
  sb.to_string()
}

///|
/// Report is the result of comparing one path.
pub(all) struct Report {
  path : String
  same : Bool
  text : String
}

///|
/// compare compares what the Go blog and the MoonBit Worker answered for
/// path, where Err holds why fetching failed. The report names each part
/// that differs (status, content-type, body) and shows a diff of the body.
pub fn compare(
  path : String,
  go : Result[Fetched, String],
  moonbit : Result[Fetched, String],
  max_lines~ : Int32 = 40,
) -> Report {
  let (g, m) = match (go, moonbit) {
    (Ok(g), Ok(m)) => (g, m)
    _ => {
      let sb = StringBuilder()
      sb.write_string("\{path}: error\n")
      if go is Err(e) {
        sb.write_string("  go: \{e}\n")
      }
      if moonbit is Err(e) {
        sb.write_string("  moonbit: \{e}\n")
      }
      return { path, same: false, text: sb.to_string(), }
    }
  }
  let parts = []
  let details = StringBuilder()
  if g.status != m.status {
    parts.push("status")
    details.write_string("  status: go \{g.status}, moonbit \{m.status}\n")
  }
  if g.content_type != m.content_type {
    parts.push("content-type")
    details.write_string(
      "  content-type: go \{g.content_type.escape()}, moonbit \{m.content_type.escape()}\n",
    )
  }
  if g.body != m.body {
    parts.push("body")
    details.write_string(
      "  body: go \{g.body.length()} chars, moonbit \{m.body.length()} chars\n",
    )
    for line in body_diff(g.body, m.body, max_lines~).split("\n") {
      if line != "" {
        details.write_string("    \{line}\n")
      }
    }
  }
  if parts.is_empty() {
    return { path, same: true, text: "\{path}: same\n", }
  }
  let header = "\{path}: differs (\{parts.join(", ")})\n"
  { path, same: false, text: header + details.to_string(), }
}

///|
/// summary is the last line of the output: how many paths differ.
pub fn summary(reports : Array[Report]) -> String {
  let differ = reports.filter(r => !r.same).length()
  "\{differ} of \{reports.length()} paths differ\n"
}
