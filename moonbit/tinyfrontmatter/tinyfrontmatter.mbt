// tinyfrontmatter splits a tiny front matter block from a document: a
// port of go/pkg/tinyfrontmatter.
//
// The block starts with a "---" line at the very beginning of the document
// and ends with the next "---" line. In between, each non-blank line is
// "key: value". The value is everything after the first ":", trimmed; one
// pair of matching surrounding quotes ("..." or '...') is removed. Nothing
// else of YAML is supported.

///|
const DELIMITER = "---"

///|
/// SPACES are the characters Go's unicode.IsSpace accepts, so trimming
/// matches strings.TrimSpace.
const SPACES = "\t\n\u{0B}\u{0C}\r \u{85}\u{A0}\u{1680}\u{2000}\u{2001}\u{2002}\u{2003}\u{2004}\u{2005}\u{2006}\u{2007}\u{2008}\u{2009}\u{200A}\u{2028}\u{2029}\u{202F}\u{205F}\u{3000}"

///|
/// SplitError is a malformed front matter block; the message says which
/// line and why, as the Go version's error does.
pub(all) suberror SplitError {
  SplitError(String)
}

///|
/// split returns the front matter of src and the rest of the document. If
/// src does not start with a "---" line, the front matter is None and the
/// rest is src unchanged. The keys keep the order they appear in.
pub fn split(src : String) -> (Map[String, String]?, String) raise SplitError {
  let (first, rest) = cut_line(src)
  if trim_line(first) != DELIMITER {
    return (None, src)
  }
  let meta : Map[String, String] = Map([])
  for rest = rest, lineno = 2; rest != ""; {
    let (raw, next) = cut_line(rest)
    let line = trim_line(raw)
    if line == DELIMITER {
      return (Some(meta), next.to_owned())
    }
    if line == "" {
      continue next, lineno + 1
    }
    guard line.find(":") is Some(i) else {
      raise SplitError(
        "tinyfrontmatter: line \{lineno}: want \"key: value\", got \{line.to_owned().escape()}",
      )
    }
    let key = line[:i].trim(chars=SPACES).to_owned()
    if key == "" {
      raise SplitError(
        "tinyfrontmatter: line \{lineno}: want \"key: value\", got \{line.to_owned().escape()}",
      )
    }
    if meta.contains(key) {
      raise SplitError(
        "tinyfrontmatter: line \{lineno}: duplicate key \{key.escape()}",
      )
    }
    meta[key] = unquote(line[i + 1:].trim(chars=SPACES))
    continue next, lineno + 1
  } nobreak {
    raise SplitError("tinyfrontmatter: no closing \{DELIMITER.escape()}")
  }
}

///|
/// cut_line is Go's strings.Cut(s, "\n"): the text before the first
/// newline and the text after it, or s and "" when there is none.
fn cut_line(s : StringView) -> (StringView, StringView) {
  match s.find("\n") {
    Some(i) => (s[:i], s[i + 1:])
    None => (s, "")
  }
}

///|
fn trim_line(s : StringView) -> StringView {
  s.trim_end(chars=" \t\r")
}

///|
fn unquote(s : StringView) -> String {
  if s is ['"' | '\'' as q, .. inner, last] && last == q {
    inner.to_owned()
  } else {
    s.to_owned()
  }
}
