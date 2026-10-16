# The spike of using MoonBit's tinymarkdown from the ts blog (../../../ts):
# lib's parse and inlines, built for the js target, return plain JS objects
# in the shape of the TS port's types, and tinymarkdown.ts here gives them
# those types. swap.mjs, a Vite plugin, resolves every import of the TS port
# to it, for ts/'s tests (vitest.config.mjs) and for the blog's build
# (vite.config.mjs). Built against the blog's packages in ../.. through
# moon.work. Needs `npm install` in ../../../ts. Run `make help` for the
# targets.

LIB := podhmo/js-tinymarkdown/lib
TS := ../../../ts
HERE := ../moonbit/experiments/js-tinymarkdown
PORT_TS ?= 8791
PORT_MOONBIT ?= 8792

.PHONY: build test bench build-blog compare clean help

## build: build lib for js into build/tinymarkdown.mjs
build:
	moon build --target js --release lib
	@mkdir -p build
	cp _build/js/release/build/$(LIB)/lib.js build/tinymarkdown.mjs

## test: run ts/'s tests, the tinymarkdown port's and the blog's, on the MoonBit build
test: build
	cd $(TS) && npx vitest run --config $(HERE)/vitest.config.mjs

## bench: check that both give the same results on the posts and documents, and time them on Node
bench: build
	node bench.mjs

## build-blog: build the ts blog into its dist/, and with the MoonBit build into build/blog/
build-blog: build
	cd $(TS) && npx vite build examples/blog && npx vite build --config $(HERE)/vite.config.mjs

## compare: serve both blogs with wrangler dev and compare every page (run build-blog first)
compare:
	cd $(TS) && { npx wrangler dev -c examples/blog/dist/blog_ts/wrangler.json --port $(PORT_TS) --inspector-port 9331 >/dev/null 2>&1 & \
		npx wrangler dev -c $(HERE)/build/blog/blog_ts/wrangler.json --port $(PORT_MOONBIT) --inspector-port 9332 >/dev/null 2>&1 & \
		trap 'kill $$(jobs -p) 2>/dev/null' EXIT; \
		for i in $$(seq 60); do curl -s -o /dev/null localhost:$(PORT_TS)/ && curl -s -o /dev/null localhost:$(PORT_MOONBIT)/ && break; sleep 1; done; \
		node $(HERE)/crawl.mjs http://localhost:$(PORT_TS) http://localhost:$(PORT_MOONBIT); }

clean:
	rm -rf _build build

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
