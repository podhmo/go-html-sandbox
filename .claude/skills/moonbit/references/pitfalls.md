# MoonBit pitfalls

Surprises that cost time and that `make check` does not point out
(anything `moon fmt --check` or `moon check` reports is left out: run it
and follow what it says). Most come from
`~/ghq/github.com/podhmo/moonbit-individual-handbook/docs/knowledge.md`,
which has more; the rest were found in this repo. Re-check an entry when
the toolchain or a pinned dependency moves.

## Toolchain

- No `moon lint` (use `moon check`), no `moon init` (use `moon new`, which
  also runs `git init` and writes `.githooks`/`.github` — do not run it
  inside this repo), `moon doc <symbol>` is deprecated (`moon ide doc`).
- `moon ide doc` on a dependency reads the registry's symbol index, which
  can be another version than the one in `moon.mod`. Read the tag-pinned
  clone instead.
- The newest library release can require a newer `moon`; it then fails
  to read the library's `moon.pkg`.
- Without `moon update`, `moon add` resolves against a stale index and
  picks old versions.
- `RUST_LOG` in the environment makes moon print tracing to stderr; unset
  it in scripts that check stderr.
- `moon -C <dir> <cmd>` runs from outside the module (the option goes
  before the subcommand).

## Targets

- An import declared as `fn f(x : Int32) = "host" "f"` does not compile on
  native (`[4156] import is unsupported in native backend`), and
  `extern "C"` does not compile on wasm. Restrict the package with
  `supported_targets`, or split files with `options(targets: ...)`.
- async's I/O is native only; wasm-gc is unsupported, so async cannot go
  into the Worker.
- On js, `@env.args()` includes node's path and the script's path.
- `--profile` needs native and, on macOS, full Xcode (`xctrace`).

## I/O and strings

- stdin is not in core or x; it is `moonbitlang/async/stdio`. core and x
  only have `println`/`eprintln` (always with a newline);
  `@stdio.stdout.write(s)` writes without one.
- `@stdio.stdin.read_all()` returns `&Data`: `.text()` decodes UTF-8,
  `.binary()` gives bytes. Call them inside `async` code.
- `StringBuilder` is for characters, `Buffer` for bytes. `Buffer`'s
  `to_string` reads its bytes as UTF-16LE, so mixing them garbles
  non-ASCII text; ASCII-only tests pass by accident.
- `String`'s `compare` (so `<`, `sort()`) orders shorter strings first:
  `"b" < "aa"` is true and `["b", "aa", "ab"].sort()` gives
  `[b, aa, ab]`. Use `a.lexical_compare(b)` for dictionary order, e.g.
  `sort_by((a, b) => a.lexical_compare(b))`, when the order must match
  Go's `sort.Strings` or file listings.
- `String::split` returns `Iter[StringView]`; `to_owned()` makes Strings.

## Library behavior

- `Array::sort` is not stable; `stable_sort` exists only on
  `MutArrayView` and `FixedArray`.
- `Map` keeps insertion order.
- `derive(ToJson)` on enums is externally tagged
  (`["Axes",{"x":-1,"y":1}]` for labelled arguments), unlike what
  `derive.md` shows; the tag key cannot be renamed through derive.
- There is no function to format a Double with a fixed number of digits,
  and `x/time` has no local time zone or formatting.
