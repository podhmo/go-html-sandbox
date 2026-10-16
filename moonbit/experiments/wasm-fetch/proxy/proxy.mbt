///|
/// host_fetch asks the host to GET the URL written at address 0, n bytes
/// long, and returns a ticket for the result, "status\n" and the body,
/// which host_take then copies in. The host wraps it in
/// WebAssembly.Suspending, so the Wasm waits here for the fetch.
fn host_fetch(n : Int32) -> Int32 = "host" "fetch"

///|
/// host_take copies the result of ticket to address 0 and returns its
/// length. It does not suspend, so no other request runs between it and
/// the read after it.
fn host_take(ticket : Int32) -> Int32 = "host" "take"

///|
/// host_done hands the host the response at address 0, n bytes long,
/// before another request can write over it.
fn host_done(id : Int32, n : Int32) -> Unit = "host" "done"

///|
fn fetch(url : String) -> (String, String) {
  let n = write_text(url)
  let len = host_take(host_fetch(n))
  let s = read_text(len)
  match s.find("\n") {
    Some(i) => (s[:i].to_owned(), s[i + 1:].to_owned())
    None => ("", s)
  }
}

///|
let app : @http.Router = {
  let r = @http.Router()
  r.handle("GET /proxy", req => {
    let url = req.query().get("url").unwrap_or("https://example.com/")
    let (status, body) = fetch(url)
    @http.Response::text(
      200,
      "upstream \{status}, \{body.length()} chars\n\{body[:if body.length() < 80 { body.length() } else { 80 }]}\n",
    )
  })
  r.handle("GET /slow/{name}", req => {
    let (status, body) = fetch(req.query().get("url").unwrap_or(""))
    @http.Response::text(200, "\{req.param("name")} \{status} \{body}\n")
  })
  r.handle("GET /twice", _ => {
    let (a, _) = fetch("https://example.com/")
    let (b, _) = fetch("https://example.org/")
    @http.Response::text(200, "\{a} \{b}\n")
  })
  r
}

///|
pub fn serve(id : Int32, n : Int32) -> Unit {
  host_done(id, @wasm.handle(n, req => app.serve(req)))
}
