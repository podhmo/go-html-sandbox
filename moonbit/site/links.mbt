// Resolving the URLs of Markdown links: a port of the Go blog's links.go,
// with the part of net/url and path it relies on.

///|
/// REPO_HOST and REPO_PATH are where files of the repository that the site
/// does not serve are linked to: the main branch on GitHub.
const REPO_HOST = "github.com"

///|
const REPO_PATH = "/podhmo/html-sandbox/blob/main"

///|
/// POSTS_DIR is the directory of the repository that holds the posts.
const POSTS_DIR = "go/examples/blog/posts"

///|
/// post_source is the file path of p in the repository.
fn post_source(p : Post) -> String {
  "\{POSTS_DIR}/\{p.file}"
}

///|
/// Ref is a URL as Go's url.Parse splits it, keeping what the linker
/// needs.
priv struct Ref {
  scheme : String
  path : String // unescaped
  raw_query : String
  fragment : String // unescaped
}

///|
/// parse_ref parses raw as Go's url.Parse does, or returns None where it
/// fails: control characters, a "%" not followed by two hex digits, a
/// missing scheme before ":", or a colon in the first segment of a
/// relative path. The authority after "//" is not checked.
fn parse_ref(raw : String) -> Ref? {
  for c in raw {
    if c.to_int() < 0x20 || c == '\u{7F}' {
      return None
    }
  }
  let (rest, fragment) = match raw.find("#") {
    Some(i) => (raw[:i], unescape(raw[i + 1:]))
    None => (raw, Some(""))
  }
  guard fragment is Some(fragment) else { return None }
  let mut scheme = ""
  let mut rest = rest
  for i, c in rest {
    match c {
      'a'..<='z' | 'A'..<='Z' => continue
      '0'..<='9' | '+' | '-' | '.' if i > 0 => continue
      ':' if i == 0 => return None
      ':' => {
        scheme = rest[:i].to_lower().to_owned()
        rest = rest[i + 1:]
      }
      _ => ()
    }
    break
  }
  let (rest, raw_query) = match rest.find("?") {
    Some(i) => (rest[:i], rest[i + 1:].to_owned())
    None => (rest, "")
  }
  if !rest.has_prefix("/") {
    if scheme != "" {
      // Opaque, such as mailto:a@example.com.
      return Some({ scheme, path: "", raw_query, fragment, })
    }
    let segment = match rest.find("/") {
      Some(i) => rest[:i]
      None => rest
    }
    if segment.contains(":") {
      return None
    }
  }
  let rest = if rest.has_prefix("//") &&
    (scheme != "" || !rest.has_prefix("///")) {
    match rest[2:].find("/") {
      Some(i) => rest[2 + i:]
      None => ""
    }
  } else {
    rest
  }
  guard unescape(rest) is Some(path) else { return None }
  Some({ scheme, path, raw_query, fragment, })
}

///|
/// unescape decodes %XX escapes, or returns None for a malformed one.
fn unescape(s : StringView) -> String? {
  guard s.contains("%") else { return Some(s.to_owned()) }
  let bytes = Buffer()
  let mut i = 0
  while i < s.length() {
    if s[i] == '%' {
      guard i + 2 < s.length() &&
        hex_value(s[i + 1]) is Some(hi) &&
        hex_value(s[i + 2]) is Some(lo) else {
        return None
      }
      bytes.write_byte((hi * 16 + lo).to_byte())
      i += 3
    } else {
      let end = match s[i:].find("%") {
        Some(j) => i + j
        None => s.length()
      }
      bytes.write_bytes(@utf8.encode(s[i:end]))
      i = end
    }
  }
  Some(@utf8.decode_lossy(bytes.to_bytes()))
}

///|
fn hex_value(c : UInt16) -> Int32? {
  let c = c.to_int()
  if c >= '0'.to_int() && c <= '9'.to_int() {
    Some(c - '0'.to_int())
  } else if c >= 'a'.to_int() && c <= 'f'.to_int() {
    Some(c - 'a'.to_int() + 10)
  } else if c >= 'A'.to_int() && c <= 'F'.to_int() {
    Some(c - 'A'.to_int() + 10)
  } else {
    None
  }
}

///|
/// escape percent-encodes s the way Go's url package writes a path, or a
/// fragment when fragment is true: every UTF-8 byte except the unreserved
/// characters and those the part allows.
fn escape(s : String, fragment~ : Bool) -> String {
  let sb = StringBuilder()
  for b in @utf8.encode(s) {
    let c = b.to_int().unsafe_to_char()
    let keep = match c {
      'a'..<='z' | 'A'..<='Z' | '0'..<='9' | '-' | '_' | '.' | '~' => true
      '$' | '&' | '+' | ',' | '/' | ':' | ';' | '=' | '@' => true
      '?' | '!' | '(' | ')' | '*' => fragment
      _ => false
    }
    if keep {
      sb.write_char(c)
    } else {
      sb <+ "%\{hex_digits[b.to_int() >> 4]}\{hex_digits[b.to_int() & 15]}"
    }
  }
  sb.to_string()
}

///|
let hex_digits : ReadOnlyArray[Char] = [
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F',
]

///|
/// clean is Go's path.Clean: the shortest path equal to p, with "." and
/// ".." elements and repeated slashes resolved.
fn clean(p : String) -> String {
  if p == "" {
    return "."
  }
  let rooted = p.has_prefix("/")
  let out : Array[StringView] = []
  for elem in p.split("/") {
    match elem {
      "" | "." => ()
      ".." =>
        if out is [.., last] && last != ".." {
          out.pop() |> ignore
        } else if !rooted {
          out.push(elem)
        }
      _ => out.push(elem)
    }
  }
  let joined = out.map(e => e.to_owned()).join("/")
  if rooted {
    "/\{joined}"
  } else if joined == "" {
    "."
  } else {
    joined
  }
}

///|
/// join is Go's path.Join: the non-empty elements joined with "/", then
/// cleaned.
fn join(elems : Array[String]) -> String {
  let parts = elems.filter(e => e != "")
  if parts.is_empty() {
    ""
  } else {
    clean(parts.join("/"))
  }
}

///|
/// dir is Go's path.Dir: all but the last element of p, cleaned.
fn dir(p : String) -> String {
  match p.rev_find("/") {
    Some(i) => clean(p[:i + 1].to_owned())
    None => "."
  }
}

///|
/// Linker resolves the URL of a Markdown link to an href, or None when the
/// URL must not be linked; the link text is then shown as plain text.
type Linker = (String) -> String?

///|
/// linker returns the Linker for links written in the file at source (a
/// path in the repository).
///
/// Links with a scheme are kept for http, https, and mailto only, so a
/// post cannot run script through a "javascript:" URL. Links to "/..." and
/// "#..." are kept as they are. Other links are relative to source, as on
/// GitHub: those to a document or post served here go to its page, others
/// go to the file on GitHub, and those that leave the repository are not
/// linked.
fn Site::linker(self : Site, source : String) -> Linker {
  raw => {
    guard parse_ref(raw) is Some(u) else { return None }
    if u.scheme != "" {
      return if u.scheme is ("http" | "https" | "mailto") {
        Some(raw)
      } else {
        None
      }
    }
    if raw is ("" | ['/' | '#', ..]) {
      return Some(raw)
    }
    let p = join([dir(source), u.path])
    if p == ".." || p.has_prefix("../") {
      return None
    }
    let href = if self.by_source.get(p) is Some(d) {
      escape(doc_path(d), fragment=false)
    } else if self.by_file.get(p) is Some(post) {
      escape(post_path(post), fragment=false)
    } else {
      // The file on the main branch on GitHub, which redirects blob/ to
      // tree/ for directories.
      let path = join([REPO_PATH, p])
      let query = if u.raw_query != "" { "?\{u.raw_query}" } else { "" }
      "https://\{REPO_HOST}\{escape(path, fragment=false)}\{query}"
    }
    let fragment = if u.fragment != "" {
      "#\{escape(u.fragment, fragment=true)}"
    } else {
      ""
    }
    Some("\{href}\{fragment}")
  }
}
