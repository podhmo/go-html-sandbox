//go:build js && wasm

// Command blog, built for js/wasm, serves the embedded blog on Cloudflare
// Workers through syumai/workers-go. There are no flags: the public origin
// for OGP tags comes from the BASE_URL variable in wrangler.jsonc.
//
// workers-go starts a new Wasm instance for every request, so main, and
// with it the parsing of every post and document, runs once per request.
package main

import (
	"net/http"

	"github.com/syumai/workers-go"
	"github.com/syumai/workers-go/cloudflare"
)

func main() {
	h, err := newWorkersHandler()
	if err != nil {
		h = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		})
	}
	workers.Serve(h)
}

func newWorkersHandler() (http.Handler, error) {
	postsFS, docsFS, err := embeddedSources()
	if err != nil {
		return nil, err
	}
	posts, err := loadPosts(postsFS)
	if err != nil {
		return nil, err
	}
	docs, err := loadDocs(docsFS)
	if err != nil {
		return nil, err
	}
	return newServer(cloudflare.Getenv("BASE_URL"), posts, docs)
}
