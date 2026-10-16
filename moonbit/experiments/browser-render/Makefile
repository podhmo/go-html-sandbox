# The spike of calling tinymarkdown and el from the browser, without a
# server: lib's render, built for the js and the wasm-gc targets, run by
# an editor page (index.html) that previews the Markdown as it is typed.
# Built against the blog's packages in ../.. through moon.work. Run
# `make help` for the targets.

OUT := _build
LIB := build/podhmo/browser-render/lib
PORT ?= 8000
WRANGLER ?= npx wrangler@4
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

.PHONY: build try serve dev screenshot clean help

## build: build render for js and wasm-gc into build/lib.mjs and build/lib.wasm
build:
	moon build --target js --release lib
	moon build --target wasm-gc --release lib
	@mkdir -p build
	cp $(OUT)/js/release/$(LIB)/lib.js build/lib.mjs
	cp $(OUT)/wasm-gc/release/$(LIB)/lib.wasm build/lib.wasm

## try: call render of both builds on Node
try: build
	node try.mjs

## serve: serve the editor page on http://localhost:PORT/ (default 8000)
serve: build
	python3 -m http.server $(PORT)

## dev: serve the page as Static Assets with wrangler dev on http://localhost:PORT/; the Worker only hands out the files
dev: build
	$(WRANGLER) dev --assets . --compatibility-date 2026-10-01 --port $(PORT)

## screenshot: take build/editor.png of the page with headless Chrome (run `make serve` or `make dev` first)
screenshot:
	"$(CHROME)" --headless=new --disable-gpu --virtual-time-budget=3000 \
		--window-size=1200,700 --screenshot=build/editor.png http://localhost:$(PORT)/

clean:
	rm -rf _build build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
