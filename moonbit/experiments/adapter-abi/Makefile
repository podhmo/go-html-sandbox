# The spikes of PR #31 (docs/sketch/ja/moonbit-workers-adapter.md): one
# package per way of passing the request and the response, built against
# the blog in ../.. through moon.work. Run `make help` for the targets.

OUT := _build/wasm-gc/release/build/podhmo/adapter-abi
BUILD := workers/build
WASM_OPT ?= moon-wasm-opt
WASM_OPT_FLAGS := -Oz --enable-gc --enable-reference-types --enable-bulk-memory \
	--enable-sign-ext --enable-nontrapping-float-to-int --enable-mutable-globals \
	--enable-multivalue
PORT ?= 8787
WRANGLER ?= npx wrangler@4
V ?= v0

.PHONY: build bench dev clean help

## build: build every spike into workers/build/<name>.wasm, and the -Oz variants the workers/worker-*oz.mjs import
build:
	$(MAKE) -C ../.. embed
	moon build --target wasm-gc --release
	@mkdir -p $(BUILD)
	cp $(OUT)/v0/v0.wasm $(BUILD)/v0.wasm
	cp $(OUT)/packed/packed.wasm $(BUILD)/packed.wasm
	cp $(OUT)/mem16/mem16.wasm $(BUILD)/mem16.wasm
	cp $(OUT)/utf8enc/utf8enc.wasm $(BUILD)/utf8.wasm
	cp $(OUT)/utf8d/utf8d.wasm $(BUILD)/utf8d.wasm
	cp $(OUT)/jsstr/jsstr.wasm $(BUILD)/jsstr.wasm
	cp $(OUT)/bench/bench.wasm $(BUILD)/bench.wasm
	cp $(OUT)/bench_js/bench_js.wasm $(BUILD)/bench_js.wasm
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(BUILD)/v0.wasm -o $(BUILD)/v0-Oz.wasm
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(BUILD)/utf8.wasm -o $(BUILD)/utf8-Oz.wasm
	$(WASM_OPT) $(WASM_OPT_FLAGS) $(BUILD)/utf8d.wasm -o $(BUILD)/utf8d-Oz.wasm
	$(WASM_OPT) $(WASM_OPT_FLAGS) --enable-strings $(BUILD)/jsstr.wasm -o $(BUILD)/jsstr-Oz.wasm
	@ls -l $(BUILD)

## bench: check that the spikes answer like v0 and time them on Node (VARIANTS= to pick, v0 first)
VARIANTS ?= v0 v0oz packed mem16 utf8 utf8d utf8doz jsstr
bench: build
	node bench.mjs workers $(VARIANTS)

## dev: serve one spike with wrangler dev (V=v0, mem16, utf8, utf8oz, or jsstr)
dev: build
	cd workers && $(WRANGLER) dev --config wrangler-$(V).jsonc --port $(PORT)

clean:
	rm -rf _build $(BUILD) .gen

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
