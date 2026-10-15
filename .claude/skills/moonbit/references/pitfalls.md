# MoonBit pitfalls

Surprises that cost time, each found by running the toolchain
(moon 0.1.20260920). Most come from
`~/ghq/github.com/podhmo/moonbit-individual-handbook/docs/knowledge.md`,
which has more; the rest were found in this repo. Re-check an entry when
the toolchain or a pinned dependency moves.

## Toolchain

- No `moon lint` (use `moon check`), no `moon init` (use `moon new`, which
  also runs `git init` and writes `.githooks`/`.github` — do not run it
  inside this repo), `moon doc <symbol>` is deprecated (`moon ide doc`).
- `moon ide doc` on a dependency reads the registry's symbol index, which
  can be another version than the one in `moon.mod` (showed async 0.21.3
  with 0.22.4 pinned). Read the tag-pinned clone instead.
- The newest library release can require a newer `moon`: async 0.22.5 on
  moon 0.1.20260920 fails with `Unexpected key 'max_concurrent_tests'
  found in moon.pkg`.
- Without `moon update`, `moon add` resolves against a stale index and
  picks old versions.
- `moon fmt` converts `moon.pkg.json` to `moon.pkg` syntactically only;
  keys it does not know stay inside `options(...)`.
- `RUST_LOG` in the environment makes moon print tracing to stderr; unset
  it in scripts that check stderr.
- `moon -C <dir> <cmd>` runs from outside the module (the option goes
  before the subcommand).

## Targets

- An import declared as `fn f(x : Int) = "host" "f"` does not compile on
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
- `String::split` returns `Iter[StringView]`; `to_owned()` makes Strings.

## Language and library

- `for .. else` is a parse error; the keyword is `nobreak`.
- `derive(Show)` is deprecated, and so are the `Show` impls of Array,
  Option, Map, tuples and Json (use `debug_inspect` in tests).
  `Iterator` is a deprecated alias of `Iter`; `try?` is deprecated.
- `derive(Debug)` on a `pub` type warns `implicit_impl_as_method`.
- `Array::sort` is not stable; `stable_sort` exists only on
  `MutArrayView` and `FixedArray`.
- `Map` keeps insertion order.
- `derive(ToJson)` on enums is externally tagged
  (`["Axes",{"x":-1,"y":1}]` for labelled arguments), unlike what
  `derive.md` shows; the tag key cannot be renamed through derive.
- Adding a variant to a `#non_exhaustive` enum turns matches without `..`
  into `partial_match` errors.
- There is no function to format a Double with a fixed number of digits,
  and `x/time` has no local time zone or formatting.
