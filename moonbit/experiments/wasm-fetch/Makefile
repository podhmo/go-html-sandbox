# The spike of awaiting the host's fetch from the Wasm through JSPI
# (docs/sketch/ja/moonbit-workers-http.md), built against the blog's http
# library in ../.. through moon.work. Run `make help` for the targets.

OUT := _build/wasm-gc/release/build/podhmo/wasm-fetch
PORT ?= 8787
WRANGLER ?= npx wrangler@4

.PHONY: build try concurrent dev detect clean help

## build: build the Wasm into build/proxy.wasm
build:
	moon build --target wasm-gc --release
	@mkdir -p build
	cp $(OUT)/proxy/proxy.wasm build/proxy.wasm

## try: fetch https://example.com/ from the Wasm on Node
try: build
	node try.mjs

## concurrent: three requests at once on Node, against a local upstream that answers late
concurrent: build
	node concurrent.mjs

## dev: serve it with wrangler dev; try /proxy?url=https://example.com/ and /twice
dev: build
	$(WRANGLER) dev --port $(PORT)

## detect: serve a Worker that tells whether WebAssembly.Suspending and promising exist
detect:
	$(WRANGLER) dev --config wrangler-detect.json --port $(PORT)

clean:
	rm -rf _build build .wrangler

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
