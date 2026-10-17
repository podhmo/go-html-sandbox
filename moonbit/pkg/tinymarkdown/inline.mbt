///|
/// Inline is a piece of the text held by a Section title, a Paragraph, or a
/// List item. Block parsing leaves that text as is; inlines splits it.
///
/// - Text is plain text.
/// - Code is the content of a `code` span.
/// - Link is a [text](url) link. children hold the parsed text, which may
///   contain code spans but no links; url is as written, and resolving it
///   is up to the renderer.
pub(all) enum Inline {
  Text(String)
  Code(String)
  Link(children~ : Array[Inline], url~ : String)
} derive(Eq, Debug)

///|
#deprecated("Use == and != instead")
pub extend Inline with Eq::{not_equal, equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Inline with Debug::{to_repr}

///|
/// inlines splits s into Text, Code, and Link.
///
/// As in CommonMark, a code span opens with a run of backquotes and closes
/// with the next run of the same length, so a span opened by two backquotes
/// may hold a single one. Line breaks inside a span become spaces, and one
/// space is stripped from each end when both ends have one, so that a span
/// can start or end with a backquote. A run with no closing run is plain
/// text.
///
/// A link is "[", text, "](", a URL, and ")". The text may not contain
/// brackets outside code spans, and the URL may not contain spaces,
/// parentheses, or line breaks; there is no title. Code spans bind tighter
/// than links: a "]" inside a code span does not close the text, and a link
/// inside a code span is code. Anything that does not form a link is plain
/// text.
pub fn inlines(s : String) -> Array[Inline] {
  split_inlines(s, links=true)
}

///|
fn split_inlines(s : String, links~ : Bool) -> Array[Inline] {
  let out = []
  let mut text = 0 // start of the plain text not yet emitted
  let n = s.length()
  let mut i = 0
  while i < n {
    if s[i] == '`' {
      let m = backquotes(s, i)
      let end = closing_run(s, from=i + m, n=m)
      if end < 0 {
        i += m
        continue
      }
      if text < i {
        out.push(Text(s[text:i].to_owned()))
      }
      out.push(Code(code_text(s[i + m:end])))
      i = end + m
      text = i
    } else if s[i] == '[' && links {
      match link(s, i) {
        None => i += 1
        Some((label, url, end)) => {
          if text < i {
            out.push(Text(s[text:i].to_owned()))
          }
          out.push(Link(children=split_inlines(label, links=false), url~))
          i = end
          text = i
        }
      }
    } else {
      i += 1
    }
  }
  if text < n {
    out.push(Text(s[text:].to_owned()))
  }
  out
}

///|
/// link parses a link starting at s[i] == '['. It returns the text, the
/// URL, and the index just past the closing ")".
fn link(s : String, i : Int32) -> (String, String, Int32)? {
  let j = for j = i + 1; j < s.length() && s[j] != ']'; j = j + 1 {
    if s[j] == '[' {
      return None
    }
    if s[j] == '`' {
      let n = backquotes(s, j)
      let c = closing_run(s, from=j + n, n~)
      continue if c >= 0 { c + n } else { j + n }
    }
  } nobreak {
    j
  }
  guard j + 1 < s.length() && s[j + 1] == '(' else { return None }
  let label = s[i + 1:j].to_owned()
  let k = for k = j + 2; k < s.length() && s[k] != ')'; k = k + 1 {
    if s[k] is (' ' | '\t' | '\n' | '(') {
      return None
    }
  } nobreak {
    k
  }
  guard k < s.length() else { return None }
  Some((label, s[j + 2:k].to_owned(), k + 1))
}

///|
/// backquotes returns the length of the run of backquotes at s[i:]. It counts
/// them directly, where trim_start would build a view and a character set for
/// every call.
fn backquotes(s : String, i : Int32) -> Int32 {
  let n = s.length()
  let mut j = i
  while j < n && s[j] == '`' {
    j = j + 1
  }
  j - i
}

///|
/// closing_run returns the index of the first run of exactly n backquotes
/// in s[from:], or -1.
fn closing_run(s : String, from~ : Int32, n~ : Int32) -> Int32 {
  for j = from; j < s.length(); {
    if s[j] != '`' {
      continue j + 1
    }
    let m = backquotes(s, j)
    if m == n {
      return j
    }
    continue j + m
  } nobreak {
    -1
  }
}

///|
fn code_text(s : StringView) -> String {
  let s = if s.contains("\n") { s.replace_all(old="\n", new=" ") } else { s }
  if s is [' ', .. inner, ' '] && inner.trim(chars=" ") != "" {
    inner.to_owned()
  } else {
    s.to_owned()
  }
}
