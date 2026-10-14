// Command workers serves the embedded blog on Cloudflare Workers through
// syumai/workers-go. It is a module of its own so that only it depends on
// workers-go; the rest of the repository stays standard-library only.
// There are no flags: the public origin for OGP tags comes from the
// BASE_URL variable in wrangler.jsonc.
//
// workers-go starts a new Wasm instance for every request, so main, and
// with it the parsing of every post and document, runs once per request.
package main

import (
	"net/http"

	"github.com/podhmo/go-html-sandbox/examples/blog/internal/site"
	"github.com/syumai/workers-go"
	"github.com/syumai/workers-go/cloudflare"
)

func main() {
	h, err := newHandler()
	if err != nil {
		h = http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			http.Error(w, err.Error(), http.StatusInternalServerError)
		})
	}
	workers.Serve(h)
}

func newHandler() (http.Handler, error) {
	postsFS, docsFS := site.EmbeddedSources()
	posts, err := site.LoadPosts(postsFS)
	if err != nil {
		return nil, err
	}
	docs, err := site.LoadDocs(docsFS)
	if err != nil {
		return nil, err
	}
	return site.NewServer(cloudflare.Getenv("BASE_URL"), posts, docs)
}
