# The spike of two Wasm modules talking in the browser: parser.wasm
# (Markdown to JSON) and html.wasm (JSON to HTML), joined on one thread
# (through JS, or linked.wasm importing html.wasm's render) and as two
# Workers over a MessagePort. Built against the blog's packages in ../..
# through moon.work. Run `make help` for the targets.

OUT := _build/wasm-gc/release/build/podhmo/wasm-pair
PORT ?= 8000
CHROME ?= /Applications/Google Chrome.app/Contents/MacOS/Google Chrome

.PHONY: build try serve check-browser clean help

## build: build parser, html and linked into build/*.wasm
build:
	moon build --target wasm-gc --release
	@mkdir -p build
	for p in parser html linked; do cp $(OUT)/$$p/$$p.wasm build/; done

## try: join the modules on Node, through JS and by linking
try: build
	node try.mjs

## serve: serve the editor page on http://localhost:PORT/ (default 8000)
serve: build
	python3 -m http.server $(PORT)

## check-browser: run /?check in headless Chrome: the three ways on a large document, and how long each stops the page
check-browser: build
	python3 -m http.server $(PORT) >/dev/null 2>&1 & pid=$$!; sleep 1; \
		node check.mjs "$(CHROME)" http://localhost:$(PORT)/?check; status=$$?; kill $$pid; exit $$status

clean:
	rm -rf _build build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
