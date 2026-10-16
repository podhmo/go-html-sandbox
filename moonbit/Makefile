# Build steps for the MoonBit blog in examples/blog, on the libraries in
# pkg/, and for the js build of tinymarkdown that the ts blog uses. The Wasm is built by moon, then run by the Worker in
# examples/blog/cloudflare/ through wrangler, whose build command runs moon
# again. Run `make help` for the targets.
#
# The blog and the libraries in pkg/ are maintained: test always runs all
# their tests, including the integration test of pkg/http/wasm, which runs
# a stub app through adapter.mjs on Node. The
# modules in experiments/ are one-off spikes that import this module
# through moon.work; check only makes sure they still build. To work on
# one part, run moon directly (`moon test -p ...`).

BLOG := examples/blog

WASM := _build/wasm-gc/release/build/$(BLOG)/worker/worker.wasm
# What the Worker imports: WASM after wasm-opt -Oz.
APP_WASM := $(BLOG)/cloudflare/build/app.wasm
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
POSTS := ../posts
# The repository's own documents, as the Go blog's repodocs embeds them.
DOCS := ../TODO.md ../docs
# The Go blog's site.css and favicon.svg.
ASSETS := ../go/examples/blog/internal/site
# The js build of tinymarkdown, and where the ts blog keeps it.
TINYMARKDOWN_JS := _build/js/release/build/pkg/tinymarkdown/js/js.js
TS_TINYMARKDOWN := ../ts/pkg/tinymarkdown/tinymarkdown.mjs
# The modules under experiments/, each with its own moon.mod.
EXPERIMENTS := $(patsubst %/moon.mod,%,$(wildcard experiments/*/moon.mod))

.PHONY: embed build ts test check dev deploy compare dev-echo clean help

## embed: regenerate the embedded.mbt files: the Go blog's posts, the repository's documents, and the Go blog's site.css and favicon.svg
# The packages' moon.pkg run the same scripts, but moon reruns them only
# when a post is added or removed, or a file directly in docs/; this
# catches edits and subdirectories too.
embed:
	sh $(BLOG)/scripts/embed.sh $(BLOG)/posts/embedded.mbt $(POSTS)
	sh $(BLOG)/scripts/embed.sh $(BLOG)/repodocs/embedded.mbt .. $(DOCS)
	sh $(BLOG)/scripts/embed-assets.sh $(BLOG)/assets/embedded.mbt $(ASSETS)

## build: build the blog's Wasm into _build/wasm-gc/release/build/examples/blog/worker/, and shrink it with wasm-opt -Oz into examples/blog/cloudflare/build/app.wasm
build: embed
	moon build --target wasm-gc --release $(BLOG)/worker
	@mkdir -p $(dir $(APP_WASM))
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(WASM) -o $(APP_WASM)
	@ls -l $(WASM) $(APP_WASM)

## ts: build pkg/tinymarkdown/js for js into ../ts/pkg/tinymarkdown/tinymarkdown.mjs, which is committed
ts:
	moon build --target js --release pkg/tinymarkdown/js
	cp $(TINYMARKDOWN_JS) $(TS_TINYMARKDOWN)

## test: run the tests, those of pkg/tinymarkdown/js on js, and the integration test of pkg/http/wasm on Node (its stub app's Wasm as moon builds it, without wasm-opt)
test: embed
	moon test
	moon test --target js -p pkg/tinymarkdown/js
	moon build --target wasm-gc --release pkg/http/wasm/integration
	node --test pkg/http/wasm/integration/test.mjs

## check: what to run before every commit (test, then moon fmt, moon check on wasm-gc and native, moon check in experiments/, moon info, and ts)
# moon info has no --check; it rewrites the .mbti files, and git diff fails
# when they differ from what is staged.
check: test
	moon fmt --check
	moon check
	moon check --target native
	for d in $(EXPERIMENTS); do (cd $$d && moon check) || exit 1; done
	moon info
	@git diff --exit-code -- '*.mbti' || { echo 'moon info changed the .mbti files above; add them to the commit' >&2; exit 1; }
	$(MAKE) ts
	@git diff --exit-code -- $(TS_TINYMARKDOWN) || { echo 'make ts changed $(TS_TINYMARKDOWN); add it to the commit' >&2; exit 1; }

## dev: serve the Worker on localhost:PORT (default 8787), rebuilding on changes
dev:
	cd $(BLOG)/cloudflare && $(WRANGLER) dev --port $(PORT)

## deploy: deploy the Worker as blog, replacing the Go blog
deploy:
	cd $(BLOG)/cloudflare && $(WRANGLER) deploy

## compare: compare the Go blog at GO_URL with the Worker at MOONBIT_URL (PATHS= to pick paths)
compare:
	moon run --target native $(BLOG)/compare/cmd -- $(GO_URL) $(MOONBIT_URL) $(PATHS)

## dev-echo: serve the integration test's stub app on localhost:PORT with wrangler
dev-echo:
	cd pkg/http/wasm/integration && $(WRANGLER) dev --port $(PORT)

## clean: remove the build output (experiments/ have their own make clean)
clean:
	rm -rf _build $(BLOG)/cloudflare/build $(BLOG)/posts/embedded.mbt $(BLOG)/repodocs/embedded.mbt $(BLOG)/assets/embedded.mbt

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
