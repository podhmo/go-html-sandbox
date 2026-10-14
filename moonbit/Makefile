# Build steps for the MoonBit blog. The Wasm is built by moon, then run by
# the Worker in workers/ through wrangler, whose build command runs moon
# again. Run `make help` for the targets.

WASM := _build/wasm-gc/release/build/worker/worker.wasm
PORT ?= 8787
WRANGLER ?= npx wrangler@4

.PHONY: build test check dev deploy clean help

## build: build the Wasm into _build/wasm-gc/release/build/worker/
build:
	moon build --target wasm-gc --release
	@ls -l $(WASM)

## test: run the tests
test:
	moon test

## check: what to run before every commit (moon fmt, moon check, moon test)
check:
	moon fmt --check
	moon check
	moon test

## dev: serve the Worker on localhost:PORT (default 8787), rebuilding on changes
dev:
	cd workers && $(WRANGLER) dev --port $(PORT)

## deploy: deploy the Worker as blog-moonbit
deploy:
	cd workers && $(WRANGLER) deploy

## clean: remove the build output
clean:
	rm -rf _build workers/build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
