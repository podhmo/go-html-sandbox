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

.PHONY: build test check dev deploy compare clean help

## build: build the Wasm into _build/wasm-gc/release/build/worker/
build:
	moon build --target wasm-gc --release
	@ls -l $(WASM)

## test: run the tests
test:
	moon test

## check: what to run before every commit (moon fmt, moon check on wasm-gc and native, moon test)
check:
	moon fmt --check
	moon check
	moon check --target native
	moon test

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
	rm -rf _build workers/build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
