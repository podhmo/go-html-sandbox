# Build steps for the MoonBit blog. The Wasm is built by moon, then run by
# the Worker in workers/ through wrangler, whose build command runs moon
# again. Run `make help` for the targets.

WASM := _build/wasm-gc/release/build/worker/worker.wasm
PORT ?= 8787
WRANGLER ?= npx wrangler@4
# compare's base URLs: the Go blog (`go run ./examples/blog` in ../go) and
# the Worker (`make dev`).
GO_URL ?= http://localhost:8080
MOONBIT_URL ?= http://localhost:$(PORT)
POSTS := ../go/examples/blog/posts

.PHONY: embed build test check dev deploy compare clean help

## embed: regenerate posts/embedded.mbt from the Go blog's posts
# posts/moon.pkg runs the same script, but moon reruns it only when a post
# is added or removed; this catches edits to a post too.
embed:
	sh scripts/embed.sh posts/embedded.mbt $(POSTS)

## build: build the Wasm into _build/wasm-gc/release/build/worker/
build: embed
	moon build --target wasm-gc --release
	@ls -l $(WASM)

## test: run the tests
test: embed
	moon test

## check: what to run before every commit (moon fmt, moon check on wasm-gc and native, moon test, moon info)
# moon info has no --check; it rewrites the .mbti files, and git diff fails
# when they differ from what is staged.
check: embed
	moon fmt --check
	moon check
	moon check --target native
	moon test
	moon info
	@git diff --exit-code -- '*.mbti' || { echo 'moon info changed the .mbti files above; add them to the commit' >&2; exit 1; }

## dev: serve the Worker on localhost:PORT (default 8787), rebuilding on changes
dev:
	cd workers && $(WRANGLER) dev --port $(PORT)

## deploy: deploy the Worker as blog-moonbit
deploy:
	cd workers && $(WRANGLER) deploy

## compare: compare the Go blog at GO_URL with the Worker at MOONBIT_URL (PATHS= to pick paths)
compare:
	moon run --target native compare/cmd -- $(GO_URL) $(MOONBIT_URL) $(PATHS)

## clean: remove the build output
clean:
	rm -rf _build workers/build posts/embedded.mbt

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
