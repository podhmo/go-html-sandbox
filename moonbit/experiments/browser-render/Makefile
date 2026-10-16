# The spike of calling tinymarkdown and el in the browser from the
# wasm-gc build alone, with no JS that MoonBit generates: lib's render,
# built with the JS string builtins, run by an editor page (index.html)
# that previews the Markdown as it is typed. The js build of the same
# render is the baseline (baseline.html). Built against the blog's
# packages in ../.. through moon.work. Run `make help` for the targets.

LIB := build/podhmo/browser-render/lib
PORT ?= 8000
WRANGLER ?= npx wrangler@4
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

.PHONY: build try serve dev dev-worker screenshot clean help

## build: build render into build/lib.wasm, and the baseline into build/lib.mjs
build:
	moon build --target wasm-gc --release lib
	moon build --target js --release lib
	@mkdir -p build
	cp _build/wasm-gc/release/$(LIB)/lib.wasm build/lib.wasm
	cp _build/js/release/$(LIB)/lib.js build/lib.mjs

## try: compile build/lib.wasm on Node with and without the builtins, and call render; then the baseline
try: build
	node try.mjs

## serve: serve the editor page on http://localhost:PORT/ (default 8000), and the baseline on /baseline.html
serve: build
	python3 -m http.server $(PORT)

## dev: serve the page as Static Assets with wrangler dev on http://localhost:PORT/; the Worker only hands out the files
dev: build
	$(WRANGLER) dev --assets . --compatibility-date 2026-10-01 --port $(PORT)

## dev-worker: serve worker.mjs, which calls render inside the Worker (and the baseline), with wrangler dev on http://localhost:PORT/
dev-worker: build
	$(WRANGLER) dev --config wrangler-worker.json --port $(PORT)

## screenshot: take build/editor.png of the page with headless Chrome (run `make serve` or `make dev` first)
screenshot:
	"$(CHROME)" --headless=new --disable-gpu --virtual-time-budget=3000 \
		--window-size=1200,700 --screenshot=build/editor.png http://localhost:$(PORT)/

clean:
	rm -rf _build build .wrangler

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
