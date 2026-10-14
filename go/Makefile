# Build steps in order: go generate copies ../TODO.md and ../docs into the
# module so the blog can embed them, then the usual go commands run.
# Run `make help` for the targets.

BIN := bin/blog

.PHONY: build generate run watch test check clean help

## build: copy the documents in and build the blog into bin/blog
build: generate
	go build -o $(BIN) ./examples/blog

## generate: copy ../TODO.md and ../docs into examples/blog/repodocs/files
generate:
	go generate ./...

## run: serve the blog with everything embedded on localhost:8080
run: generate
	go run ./examples/blog

## watch: serve the blog from files on disk, reloading on changes
watch:
	go run ./examples/blog -watch

## test: run the tests, with the documents copied in
test: generate
	go test ./...

## check: what to run before every commit (gofmt, go vet, go test)
check: generate
	@test -z "$$(gofmt -l .)" || { gofmt -l .; echo "run gofmt -w ."; exit 1; }
	go vet ./...
	go test ./...

## clean: remove bin/ and the copied documents
clean:
	rm -rf bin
	find examples/blog/repodocs/files -mindepth 1 -maxdepth 1 ! -name .gitignore -exec rm -rf {} +

help:
	@sed -n 's/^## //p' $(MAKEFILE_LIST)
