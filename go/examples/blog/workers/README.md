# blog on Cloudflare Workers (experimental)

This module serves the same site as [`examples/blog`](../) on Cloudflare
Workers through [syumai/workers-go](https://github.com/syumai/workers-go).
It is a Go module of its own so that only it depends on workers-go; the
rest of the repository stays standard-library only.

It has no flags: the public origin for OGP tags comes from `BASE_URL` in
[`wrangler.jsonc`](wrangler.jsonc). Posts and documents are embedded in
the Wasm binary, as in the server; both builds run `go generate` on
[`../repodocs`](../repodocs) first, so the documents are always fresh.

## Builds

`wrangler.jsonc` builds the Worker in one of two ways. Both are deployed as
the same Worker, `blog`, so the last deploy wins.

| | Command | Wasm binary |
| --- | --- | --- |
| TinyGo (default) | `npx wrangler dev` | about 2 MiB (760 KiB gzipped) |
| Standard Go (`GOOS=js GOARCH=wasm`) | `npx wrangler dev --env go` | about 8 MiB |

Both fit the Workers size limit. The TinyGo build needs TinyGo 0.42.0 or
later as `tinygo` on `PATH`.

### TinyGo without installing it

[`bin/tinygo`](bin/tinygo) runs TinyGo in Docker (`tinygo/tinygo:0.43.0`;
set `TINYGO_IMAGE` for another one). Put it first on `PATH`, and wrangler's
build command uses it:

```sh
cd examples/blog/workers
PATH="$PWD/bin:$PATH" npx wrangler dev
```

It mounts the whole repository, since this module replaces
`github.com/podhmo/html-sandbox/go` with `../../..`. The module and build
caches are kept in the Docker volumes `tinygo-gomod` and `tinygo-cache`, so
only the first build is slow.

## Running locally

```sh
cd examples/blog/workers
npx wrangler dev            # TinyGo
npx wrangler dev --env go   # standard Go
```

Then open <http://localhost:8787>. `BASE_URL` is the deployed URL, so OGP
tags point there even when running locally.

## Deploying

Deploying needs a Cloudflare account.

1. Log in once:

   ```sh
   cd examples/blog/workers
   npx wrangler login
   ```

2. Set the public origin. `BASE_URL` in `wrangler.jsonc` must be the URL
   the Worker is served at, `https://blog.<your-subdomain>.workers.dev`.
   It is set twice, in the top-level `vars` and in `env.go.vars`, because
   environments do not inherit `vars`. It holds the repository owner's URL;
   for your own account, change it or override it with
   `--var BASE_URL:https://...` on the command line. An empty or invalid
   `BASE_URL` makes every page a 500 error.
   Your `workers.dev` subdomain is shown in the Cloudflare dashboard under
   Workers & Pages, and wrangler prints the full URL at the end of a deploy.
   It can also be fetched from the API with the account ID that
   `npx wrangler whoami` prints and the token wrangler stored at login
   (the path below is for macOS):

   ```sh
   TOKEN=$(sed -n 's/^oauth_token = "\(.*\)"/\1/p' ~/Library/Preferences/.wrangler/config/default.toml)
   curl -s -H "Authorization: Bearer $TOKEN" \
     https://api.cloudflare.com/client/v4/accounts/<account-id>/workers/subdomain
   ```

3. Build and deploy. With TinyGo (through Docker here):

   ```sh
   PATH="$PWD/bin:$PATH" npx wrangler deploy --env=""
   ```

   `--env=""` picks the top-level config; without it, wrangler warns that
   no environment was given. With the standard Go toolchain:

   ```sh
   npx wrangler deploy --env go
   ```

   The build command in `wrangler.jsonc` runs first, so there is nothing to
   build by hand. Try `--dry-run` to build and check the upload size
   without deploying.

4. Check the site at the printed URL, e.g. that `og:url` on a post page
   starts with your `BASE_URL`. `npx wrangler tail` streams the Worker's
   logs.

Deploy again after editing posts or documents. To remove the Worker, run
`npx wrangler delete`.

## Testing

The site itself lives in [`internal/site`](../internal/site), which is
tested under TinyGo too. From the repository root:

```sh
tinygo test ./examples/blog/internal/site
```

See the [experiment report](../../../../docs/sketch/ja/blog-tinygo-workers.md)
for what TinyGo needed and how the two builds compare.
