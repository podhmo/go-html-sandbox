# Build steps for the MoonBit blog. The Wasm is built by moon, then run by
# the Worker in workers/ through wrangler, whose build command runs moon
# again. Run `make help` for the targets.

WASM := _build/wasm-gc/release/build/worker/worker.wasm
# What the Worker imports: WASM after wasm-opt -Oz.
APP_WASM := workers/build/app.wasm
# binaryen's wasm-opt, which comes with moon. -all would also enable
# features V8 cannot load yet, so only the ones moon's output uses.
WASM_OPT ?= moon-wasm-opt
WASM_OPT_FLAGS := -Oz --enable-gc --enable-reference-types --enable-bulk-memory \
	--enable-sign-ext --enable-nontrapping-float-to-int --enable-mutable-globals \
	--enable-multivalue
PORT ?= 8787
WRANGLER ?= npx wrangler@4
# compare's base URLs: the Go blog (`go run ./examples/blog` in ../go) and
# the Worker (`make dev`).
GO_URL ?= http://localhost:8080
MOONBIT_URL ?= http://localhost:$(PORT)
POSTS := ../go/examples/blog/posts
# The repository's own documents, as the Go blog's repodocs embeds them.
DOCS := ../TODO.md ../docs
# The Go blog's site.css and favicon.svg.
ASSETS := ../go/examples/blog/internal/site

.PHONY: embed build test check dev deploy compare build-echo test-echo dev-echo clean help

## embed: regenerate the embedded.mbt files: the Go blog's posts, the repository's documents, and the Go blog's site.css and favicon.svg
# The packages' moon.pkg run the same scripts, but moon reruns them only
# when a post is added or removed, or a file directly in docs/; this
# catches edits and subdirectories too.
embed:
	sh scripts/embed.sh posts/embedded.mbt $(POSTS)
	sh scripts/embed.sh repodocs/embedded.mbt .. $(DOCS)
	sh scripts/embed-assets.sh assets/embedded.mbt $(ASSETS)

## build: build the Wasm into _build/wasm-gc/release/build/worker/, and shrink it with wasm-opt -Oz into workers/build/app.wasm
build: embed
	moon build --target wasm-gc --release
	@mkdir -p $(dir $(APP_WASM))
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(WASM) -o $(APP_WASM)
	@ls -l $(WASM) $(APP_WASM)

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

## deploy: deploy the Worker as blog, replacing the Go blog
deploy:
	cd workers && $(WRANGLER) deploy

## compare: compare the Go blog at GO_URL with the Worker at MOONBIT_URL (PATHS= to pick paths)
compare:
	moon run --target native compare/cmd -- $(GO_URL) $(MOONBIT_URL) $(PATHS)

# The echo example of the http library, in examples/echo.
ECHO_WASM := _build/wasm-gc/release/build/examples/echo/echo.wasm
ECHO_APP_WASM := examples/echo/build/echo.wasm

## build-echo: build the echo example of the http library into examples/echo/build/echo.wasm
build-echo:
	moon build --target wasm-gc --release
	@mkdir -p $(dir $(ECHO_APP_WASM))
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(ECHO_WASM) -o $(ECHO_APP_WASM)
	@ls -l $(ECHO_WASM) $(ECHO_APP_WASM)

## test-echo: run the echo example on Node through http/wasm/adapter.mjs
test-echo: build-echo
	node --test examples/echo/test.mjs

## dev-echo: serve the echo example on localhost:PORT with wrangler
dev-echo:
	cd examples/echo && $(WRANGLER) dev --port $(PORT)

## clean: remove the build output
clean:
	rm -rf _build workers/build examples/echo/build posts/embedded.mbt repodocs/embedded.mbt assets/embedded.mbt

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
