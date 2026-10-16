# The timings in docs/sketch/ja/moonbit-workers-http.md: the blog's Wasm
# through PR #31's adapter and through the http library's, and the echo
# example with bodies of each size. Run `make help` for the targets.

# PR #31's last commit, and the first that routes the blog with Router.
PR31 ?= 3bf832a
LIB ?= d3e2c04
ROUTER ?= 7de0ca8

.PHONY: build bench bench-body clean help

## build: build the blog's Wasm at PR31, LIB, and ROUTER into build/
build:
	sh build-at.sh $(PR31) pr31
	sh build-at.sh $(LIB) lib
	sh build-at.sh $(ROUTER) router

## bench: time / and the largest page through each build
bench:
	node bench.mjs pr31 lib router

## bench-body: time the echo example with headers and bodies up to 1 MB
bench-body:
	$(MAKE) -C ../.. build-echo
	node bench-body.mjs

clean:
	rm -rf build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
