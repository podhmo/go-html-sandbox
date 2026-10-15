// Loading posts and documents: a port of the Go blog's posts.go and
// docs.go, reading the embedded (name, content) pairs instead of an fs.FS.

///|
/// LoadError is content that cannot be served; the message names the
/// file and the problem, as the Go blog's errors do.
pub(all) suberror LoadError {
  LoadError(String)
}

///|
/// Post is one blog post loaded from a YYYY-MM-DD-slug.md file.
pub struct Post {
  slug : String
  file : String // file name, e.g. 2026-10-14-hello.md
  date : String // YYYY-MM-DD
  title : String // front matter "title", or the first "#" heading
  description : String // front matter "description", or the first paragraph
  doc : @tinymarkdown.Document
  markdown : String // the file as written, front matter included
}

///|
/// FRONT_MATTER_KEYS are the keys a post may set; others are reported as
/// typos.
let front_matter_keys : ReadOnlyArray[String] = ["title", "description"]

///|
/// load_posts reads every *.md file in files, given as (file name,
/// content) pairs, newest first.
pub fn load_posts(
  files : ReadOnlyArray[(String, String)],
) -> Array[Post] raise LoadError {
  let seen : Map[String, String] = Map([]) // slug -> file name
  let posts = []
  for (name, src) in files {
    guard name.has_suffix(".md") else { continue }
    guard post_name(name) is Some((date, slug)) else {
      raise LoadError(
        "\{name}: file name must look like YYYY-MM-DD-slug.md (slug: a-z, 0-9, -)",
      )
    }
    if check_date(date) is Some(problem) {
      raise LoadError("\{name}: parsing time \{date.escape()}: \{problem}")
    }
    if seen.get(slug) is Some(prev) {
      raise LoadError(
        "\{name}: slug \{slug.escape()} is already used by \{prev}",
      )
    }
    seen[slug] = name
    let (meta, body) = @tinyfrontmatter.split(src) catch {
      SplitError(msg) => raise LoadError("\{name}: \{msg}")
    }
    let meta = meta.unwrap_or(Map([]))
    for k, _ in meta {
      if !front_matter_keys.contains(k) {
        raise LoadError(
          "\{name}: unknown front matter key \{k.escape()} (want one of [\{front_matter_keys.join(" ")}])",
        )
      }
    }
    let doc = @tinymarkdown.parse(body)
    let title = match meta.get("title") {
      Some(t) if t != "" => t
      _ => first_title(doc).unwrap_or("")
    }
    if title == "" {
      raise LoadError(
        "\{name}: no title (set \"title\" in front matter or start with a \"# title\" heading)",
      )
    }
    let description = match meta.get("description") {
      Some(d) if d != "" => d
      _ => first_paragraph(doc.children)
    }
    posts.push({
      slug,
      file: name,
      date,
      title,
      description,
      doc,
      markdown: src,
    })
  }
  posts.sort_by((a, b) => {
    let c = b.date.lexical_compare(a.date)
    if c != 0 {
      c
    } else {
      a.slug.lexical_compare(b.slug)
    }
  })
  posts
}

///|
/// post_name matches name against YYYY-MM-DD-slug.md, where slug is runs
/// of a-z and 0-9 joined by single "-", and returns the date and the slug.
fn post_name(name : String) -> (String, String)? {
  guard name
    is [
      '0'..<='9',
      '0'..<='9',
      '0'..<='9',
      '0'..<='9',
      '-',
      '0'..<='9',
      '0'..<='9',
      '-',
      '0'..<='9',
      '0'..<='9',
      '-',
      .. slug,
      .. ".md",
    ] else {
    return None
  }
  let mut prev_dash = true
  for c in slug {
    match c {
      'a'..<='z' | '0'..<='9' => prev_dash = false
      '-' if !prev_dash => prev_dash = true
      _ => return None
    }
  }
  if prev_dash {
    return None
  }
  Some((name[:10].to_owned(), slug.to_owned()))
}

///|
/// check_date reports what is wrong with date, digits in the form
/// YYYY-MM-DD, in the words of Go's time.Parse, or None if it is a real
/// day.
fn check_date(date : String) -> String? {
  let num = (s : StringView) => {
    let mut n = 0
    for c in s {
      n = n * 10 + (c.to_int() - '0'.to_int())
    }
    n
  }
  let year = num(date[0:4])
  let month = num(date[5:7])
  let day = num(date[8:10])
  if month < 1 || month > 12 {
    return Some("month out of range")
  }
  let leap = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
  let days = match month {
    2 => if leap { 29 } else { 28 }
    4 | 6 | 9 | 11 => 30
    _ => 31
  }
  if day < 1 || day > days {
    return Some("day out of range")
  }
  None
}

///|
/// first_title returns the title of the first top-level "#" section.
fn first_title(doc : @tinymarkdown.Document) -> String? {
  for b in doc.children {
    if b is Section(level=1, title~, ..) {
      return Some(title)
    }
  }
  None
}

///|
/// first_paragraph returns the first paragraph in document order, with line
/// breaks turned into spaces.
fn first_paragraph(bs : Array[@tinymarkdown.Block]) -> String {
  for b in bs {
    match b {
      Paragraph(text) => return text.replace_all(old="\n", new=" ")
      Section(children~, ..) => {
        let s = first_paragraph(children)
        if s != "" {
          return s
        }
      }
      _ => ()
    }
  }
  ""
}

///|
/// Doc is a repository document, such as TODO.md or docs/ja/design.md,
/// served under /docs/.
pub struct Doc {
  path : String // URL path below /docs/: the file path without "docs/" and ".md"
  source : String // file path in the repository
  title : String // the first "#" heading, or source
  description : String // the first paragraph
  doc : @tinymarkdown.Document
  markdown : String // the file as written
}

///|
/// DOC_SOURCES are the files and directories of the repository that hold
/// documents, in the order they are listed.
let doc_sources : ReadOnlyArray[String] = ["TODO.md", "docs"]

///|
/// load_docs reads every *.md file in files, given as (file path in the
/// repository, content) pairs, in the order of doc_sources and then in the
/// order Go's fs.WalkDir visits them.
pub fn load_docs(
  files : ReadOnlyArray[(String, String)],
) -> Array[Doc] raise LoadError {
  let sources = []
  for root in doc_sources {
    let found = files
      .iter()
      .filter(f => {
        f.0.has_suffix(".md") && (f.0 == root || f.0.has_prefix("\{root}/"))
      })
      .to_array()
    found.sort_by((a, b) => walk_order(a.0, b.0))
    sources.push_iter(found.iter())
  }
  let seen : Map[String, String] = Map([]) // path -> source
  let docs = []
  for (name, src) in sources {
    let p = name.strip_suffix(".md").unwrap_or(name)
    let p = p.strip_prefix("docs/").unwrap_or(p).to_owned()
    if seen.get(p) is Some(prev) {
      raise LoadError("\{name}: /docs/\{p} is already used by \{prev}")
    }
    seen[p] = name
    let doc = @tinymarkdown.parse(src)
    docs.push({
      path: p,
      source: name,
      title: first_title(doc).unwrap_or(name),
      description: first_paragraph(doc.children),
      doc,
      markdown: src,
    })
  }
  docs
}

///|
/// walk_order compares file paths the way fs.WalkDir orders them: element
/// by element, so that a directory's files come right after its name.
fn walk_order(a : String, b : String) -> Int32 {
  let xs = a.split("/").to_array()
  let ys = b.split("/").to_array()
  let n = if xs.length() < ys.length() { xs.length() } else { ys.length() }
  for i in 0..<n {
    let c = xs[i].lexical_compare(ys[i])
    if c != 0 {
      return c
    }
  }
  xs.length().compare(ys.length())
}
