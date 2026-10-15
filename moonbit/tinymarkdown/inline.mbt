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
pub extend Inline with Eq::{not_equal, equal}

///|
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
  split_inlines(s, true)
}

///|
fn split_inlines(s : String, links : Bool) -> Array[Inline] {
  let out = []
  let mut text = 0 // start of the plain text not yet emitted
  fn emit(i : Int32, inline : Inline) {
    if text < i {
      out.push(Text(s[text:i].to_owned()))
    }
    out.push(inline)
  }

  let mut i = 0
  while i < s.length() {
    if s[i] == '`' {
      let n = backquotes(s, i)
      let end = closing_run(s, i + n, n)
      if end < 0 {
        i += n
        continue
      }
      emit(i, Code(code_text(s[i + n:end].to_owned())))
      i = end + n
      text = i
    } else if s[i] == '[' && links {
      match link(s, i) {
        None => i += 1
        Some((label, url, end)) => {
          emit(i, Link(children=split_inlines(label, false), url~))
          i = end
          text = i
        }
      }
    } else {
      i += 1
    }
  }
  if text < s.length() {
    out.push(Text(s[text:].to_owned()))
  }
  out
}

///|
/// link parses a link starting at s[i] == '['. It returns the text, the
/// URL, and the index just past the closing ")".
fn link(s : String, i : Int32) -> (String, String, Int32)? {
  let mut j = i + 1
  while j < s.length() && s[j] != ']' {
    if s[j] == '[' {
      return None
    }
    if s[j] == '`' {
      let n = backquotes(s, j)
      let c = closing_run(s, j + n, n)
      j = if c >= 0 { c + n - 1 } else { j + n - 1 }
    }
    j += 1
  }
  if j + 1 >= s.length() || s[j + 1] != '(' {
    return None
  }
  let label = s[i + 1:j].to_owned()
  let mut k = j + 2
  while k < s.length() && s[k] != ')' {
    if s[k] == ' ' || s[k] == '\t' || s[k] == '\n' || s[k] == '(' {
      return None
    }
    k += 1
  }
  if k >= s.length() {
    return None
  }
  Some((label, s[j + 2:k].to_owned(), k + 1))
}

///|
/// backquotes returns the length of the run of backquotes at s[i:].
fn backquotes(s : String, i : Int32) -> Int32 {
  let rest = s[i:]
  rest.length() - rest.trim_start(chars="`").length()
}

///|
/// closing_run returns the index of the first run of exactly n backquotes
/// in s[from:], or -1.
fn closing_run(s : String, from : Int32, n : Int32) -> Int32 {
  let mut j = from
  while j < s.length() {
    if s[j] != '`' {
      j += 1
      continue
    }
    let m = backquotes(s, j)
    if m == n {
      return j
    }
    j += m
  }
  -1
}

///|
fn code_text(s : String) -> String {
  let s = s.replace_all(old="\n", new=" ")
  if s.length() >= 2 &&
    s[0] == ' ' &&
    s[s.length() - 1] == ' ' &&
    s.trim(chars=" ") != "" {
    s[1:s.length() - 1].to_owned()
  } else {
    s
  }
}
