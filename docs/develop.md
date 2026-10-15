# Development setup

What a fresh environment (such as a Claude Code cloud session) needs
before working on this repository.

## Git identity

Every commit must use this identity:

```sh
git config user.name podhmo
git config user.email ababjam61+github@gmail.com
```

## MoonBit toolchain

```sh
curl -fsSL https://cli.moonbitlang.com/install/unix.sh | bash
export PATH=$HOME/.moon/bin:$PATH
moon update   # the registry index; without it `moon check` cannot find moonbitlang/async
```

Then, from `moonbit/`, `make check` must pass before every commit (it fails
when `moon info` changed a `.mbti` that is not staged: `git add` it and
run it again).

## Stacked PRs with gh-stack

PRs for TODO.md tasks are GitHub stacked PRs: one task per branch and PR,
each branch on top of the previous one.

- `gh skill` does not exist in the container's gh, and
  `gh extension install github/gh-stack` gets a 403 for the release. Build
  it from source instead, and install the skill by copying it:

  ```sh
  git clone --depth 1 https://github.com/github/gh-stack ~/gh-stack
  (cd ~/gh-stack && go build -o gh-stack .)
  mkdir -p ~/.local/share/gh/extensions/gh-stack ~/.claude/skills
  cp ~/gh-stack/gh-stack ~/.local/share/gh/extensions/gh-stack/
  cp -r ~/gh-stack/skills/gh-stack ~/.claude/skills/
  git config rerere.enabled true
  ```

- GitHub GraphQL is blocked from these sessions, so `gh stack submit`
  pushes but cannot find or create PRs. Use `gh stack init <branches...>`,
  `gh stack add <branch>`, and `gh stack push` locally; create each PR
  with the GitHub MCP tool (base: the branch below); then link it with the
  REST API that gh-stack itself calls:

  ```sh
  # a new stack, bottom to top
  echo '{"pull_requests":[12,13]}' | gh api -X POST repos/podhmo/html-sandbox/stacks --input -
  # append to an existing stack (number from the result, or GET .../stacks;
  # the TODO.md stack started in October 2026 is stack 17)
  echo '{"pull_requests":[14]}' | gh api -X POST repos/podhmo/html-sandbox/stacks/<n>/add --input -
  ```

## Comparing the MoonBit blog with the Go blog

```sh
(cd go && go generate ./... && go run ./examples/blog -base-url https://blog-moonbit.ababjam61.workers.dev)
(cd moonbit && make dev PORT=8798)        # wrangler works through npx
(cd moonbit && make compare PORT=8798)
```

Rerun `go generate ./...` after editing `TODO.md` or `docs/`, or the Go
side serves a stale copy and the documents differ.

## Out of scope

Do not deploy (`make deploy`, `wrangler deploy`) or do deploy-only tasks.
