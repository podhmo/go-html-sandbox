// How a request and a response cross between the host (adapter.mjs) and
// the Wasm, through the Wasm's linear memory.
//
// The request, at address 0:
//
//   method \n url \n (name \t value \n)* \n (name \t value \n)* \n body
//
// the method, the URL, the headers, an empty line, the host's variables
// (env), an empty line, and the body as bytes. Everything before the body
// is UTF-8, and no name or value has a newline.
//
// The response, written over it:
//
//   status \n (name \t value \n)* \n body
//
// serve returns its length in bytes.

///|
/// decode_request parses the request in the wire format above. It raises
/// BadRequest for a request it cannot parse.
fn decode_request(data : BytesView) -> @http.Request raise @http.BadRequest {
  // The head ends at the second empty line: the headers' and env's.
  let head_end = for i, b in data; ends = 0, prev = -1 {
    if b != b'\n' {
      continue ends, prev
    }
    let ends = if prev == i - 1 { ends + 1 } else { ends }
    if ends == 2 {
      break Some(i + 1)
    }
    continue ends, i
  } nobreak {
    None
  }
  guard head_end is Some(head_end) else {
    raise @http.BadRequest(message="truncated request")
  }
  let head = @utf8.decode_lossy(data[:head_end])
  let lines = head.split("\n").collect()
  guard lines.length() >= 4 else {
    raise @http.BadRequest(message="truncated request")
  }
  let headers = @http.Headers()
  let env = Map([])
  let mut in_env = false
  for line in lines[2:] {
    if line.is_empty() {
      if in_env {
        break
      }
      in_env = true
      continue
    }
    let (name, value) = match line.find("\t") {
      Some(i) => (line[:i].to_owned(), line[i + 1:].to_owned())
      None => (line.to_owned(), "")
    }
    if in_env {
      env[name] = value
    } else {
      headers.add(name, value~)
    }
  }
  @http.Request(
    verb=lines[0].to_owned(),
    url=lines[1].to_owned(),
    headers~,
    body=data[head_end:].to_owned(),
    env~,
  )
}

///|
/// encode_head is the status and the headers of res in the wire format,
/// with the empty line that ends them. As Go's net/http writes them, a
/// field whose name is not a token is dropped, and a CR or LF in a value
/// is a space, so that no value can start another field or end the head.
fn encode_head(res : @http.Response) -> String {
  let head = StringBuilder()
  head <+ "\{res.status}\n"
  for (name, value) in res.headers {
    guard is_token(name) else { continue }
    let value = value
      .replace_all(old="\r", new=" ")
      .replace_all(old="\n", new=" ")
      .trim(chars=" \t")
    head <+ "\{name}\t\{value}\n"
  }
  head <+ "\n"
  head.to_string()
}

///|
/// is_token is whether name is a token (RFC 9110), as a field name must be.
fn is_token(name : String) -> Bool {
  !name.is_empty() &&
  name
  .iter()
  .all(c => {
    c is ('a'..<='z' | 'A'..<='Z' | '0'..<='9') ||
    "!#$%&'*+-.^_`|~".contains_char(c)
  })
}

///|
/// handle answers the request in the wire format at address 0, n bytes
/// long, with handler, and writes the response over it, returning its
/// length. A request that cannot be parsed gets 400, as Go's net/http
/// answers it.
pub fn handle(n : Int32, handler : (@http.Request) -> @http.Response) -> Int32 {
  let res = try decode_request(read(n)) catch {
    _ => @http.Response::text(400, "400 Bad Request")
  } noraise {
    req => handler(req)
  }
  let end = write(0, encode_head(res))
  match res.body {
    Text(s) => write(end, s)
    Binary(b) => write_bytes(end, b)
  }
}
