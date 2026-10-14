# TODO

> **Note on updating this file:** upkeep rules live in
> [`.claude/skills/todo-md/SKILL.md`](.claude/skills/todo-md/SKILL.md) —
> follow them whenever you add or complete a task. Short version: this file
> lists actionable work only (`[ ]` / `[-]`); mark finished work `[x]` — a
> periodic GC sweep appends such entries to `TODO-archive.md`.

This file tracks actionable tasks only; completed work is swept to
`TODO-archive.md` by periodic GC.

## To Be Implemented

### pkg/el

- [x] **Readable `PlainRenderer` output**: text of adjacent elements is
  glued together (`blog2026-10-14Hello`). Separate block-level elements
  (e.g. with newlines) and update tests in `pkg/el` and `cmd/blog`.

### pkg/tinyfrontmatter

- [x] **Tiny front matter**: split a leading `---` block of `key: value`
  lines from the Markdown body, as a separate package next to
  `pkg/tinymarkdown`. Errors for an unclosed block, a line without `:`,
  and duplicate keys.

### cmd/blog

- [x] **Front matter in posts**: `title` and `description` from
  `pkg/tinyfrontmatter`, falling back to the first `#` heading and the
  first paragraph; `description` also feeds `<meta name="description">`
  and OGP.
- [ ] **OGP support**: `og:title`, `og:type` (`website` / `article`),
  `og:url`, `og:description` (the post's description), `og:site_name`.
  Needs a base URL flag for absolute URLs and a `property` attribute
  const in `pkg/el`; `og:image` is out of scope for now.
