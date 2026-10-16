// A stub app for the integration test of http/wasm: it echoes back what
// it was given, through routes for each method, path wildcards, the
// query, and request bodies as text, JSON, and forms. ./test.mjs runs it
// on Node through ../adapter.mjs; ./worker.mjs runs it with wrangler.

///|
const PAGE =
  #|<!doctype html>
  #|<title>echo</title>
  #|<h1>echo</h1>
  #|<form method="post" action="/form">
  #|  <input name="name" value="日本語"> <input name="tag" value="a"> <input name="tag" value="b">
  #|  <button>urlencoded</button>
  #|</form>
  #|<form method="post" action="/form" enctype="multipart/form-data">
  #|  <input name="name" value="multipart"> <input type="file" name="file">
  #|  <button>multipart</button>
  #|</form>

///|
fn values_json(v : @http.Values) -> Json {
  Json::array([ for (name, value) in v.pairs => [name, value] ])
}

///|
/// request_json is what /echo answers: the request as the handler sees it.
fn request_json(req : @http.Request) -> Json {
  {
    "method": Json(req.verb),
    "host": Json(req.host),
    "path": Json(req.path),
    "query": values_json(req.query()),
    // Option's ToJson is [] or [value], so None is written as null here.
    "content_type": match req.headers.get("content-type") {
      Some(v) => Json(v)
      None => Json::null()
    },
    "body": Json(req.text()),
    "body_bytes": Json(req.body.length()),
  }
}

///|
fn router() -> @http.Router {
  let r = @http.Router()
  r.handle("GET /{$}", _ => @http.Response::html(200, PAGE))
  r.handle("GET /hello/{name}", req => {
    let greeting = req.query().get("greeting").unwrap_or("hello")
    @http.Response::text(200, "\{greeting}, \{req.param("name")}\n")
  })
  r.handle("/echo", req => @http.Response::json(200, request_json(req)))
  r.handle("POST /json", req => {
    let value = req.json() catch {
      e => return @http.Response::text(400, "\{e}\n")
    }
    @http.Response::json(200, { "got": value })
  })
  r.handle("POST /form", req => {
    let form = req.form() catch {
      e => return @http.Response::text(400, "\{e}\n")
    }
    let files = form.files.map(f => {
      "name": Json(f.name),
      "filename": Json(f.filename),
      "content_type": Json(f.content_type),
      "size": Json(f.data.length()),
    })
    @http.Response::json(200, {
      "values": values_json(form.values),
      "files": Json(files),
    })
  })
  r.handle("GET /files/{path...}", req => {
    @http.Response::text(200, "file: \{req.param("path")}\n")
  })
  r.handle("PUT /items/{id}", req => {
    @http.Response::json(200, { "id": req.param("id"), "body": req.text() })
  })
  r.handle("DELETE /items/{id}", _ => @http.Response(204))
  r.handle("GET /redirect", req => {
    let to = req.query().get("to").unwrap_or("/")
    @http.Response::redirect(303, to)
  })
  r.handle("GET /bytes", _ => {
    let body = Bytes::makei(256, i => i.to_byte())
    @http.Response::typed(200, "application/octet-stream", Binary(body))
  })
  r.handle("GET /cookie", req => {
    @http.Response::text(
      200,
      "cookie: \{req.headers.get("cookie").unwrap_or("")}\n",
    )
    ..header("set-cookie", value="a=1; Path=/")
    ..header("set-cookie", value="b=2; Path=/")
  })
  r.handle("GET /env", req => {
    @http.Response::text(
      200,
      "GREETING=\{req.env.get("GREETING").unwrap_or("")}\n",
    )
  })
  r
}

///|
let app : @http.Router = router()

///|
pub fn serve(n : Int32) -> Int32 {
  @wasm.handle(n, req => app.serve(req))
}
