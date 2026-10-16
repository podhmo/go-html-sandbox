///|
/// base_url is the public origin the site was loaded with.
let base_url : Ref[String] = Ref("")

///|
/// site is the content being served, loaded on the first request (and
/// again if BASE_URL changes), or why it could not be.
let site : Ref[Result[@site.Site, String]?] = Ref(None)

///|
/// load returns the site for base, loading it on first use.
fn load(base : String) -> Result[@site.Site, String] {
  match site.val {
    Some(s) if base == base_url.val => s
    _ => {
      base_url.val = base
      let s = Ok(@site.Site::embedded(base_url=base)) catch { e => Err("\{e}") }
      site.val = Some(s)
      s
    }
  }
}

///|
/// answer answers req with the site for the BASE_URL
/// variable. If the embedded content cannot be loaded, every request gets
/// a 500 saying why.
fn answer(req : @http.Request) -> @http.Response {
  match load(req.env.get("BASE_URL").unwrap_or("")) {
    Err(msg) => @http.Response::text(500, "\{msg}\n")
    Ok(s) => s.handle(req)
  }
}

///|
/// serve answers the request the host (../http/wasm/adapter.mjs) wrote at
/// address 0 of the memory, n bytes long, and writes the response over it,
/// returning its length; see the http/wasm package for the format.
pub fn serve(n : Int32) -> Int32 {
  @wasm.handle(n, answer)
}
