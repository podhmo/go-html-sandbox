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

# The echo example's Wasm after wasm-opt -Oz, with the flags of ../../Makefile,
# as the timings were taken.
ECHO_WASM := ../../_build/wasm-gc/release/build/examples/echo/echo.wasm
WASM_OPT ?= moon-wasm-opt
WASM_OPT_FLAGS := -Oz --enable-gc --enable-reference-types --enable-bulk-memory \
	--enable-sign-ext --enable-nontrapping-float-to-int --enable-mutable-globals \
	--enable-multivalue

## bench-body: time the echo example with headers and bodies up to 1 MB
bench-body:
	cd ../.. && moon build --target wasm-gc --release examples/echo
	@mkdir -p build
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(ECHO_WASM) -o build/echo.wasm
	node bench-body.mjs

clean:
	rm -rf build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
