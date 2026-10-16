///|
test "decode_request" {
  let data = @utf8.encode(
    "POST\nhttps://h.example/a%20b?x=1\ncontent-type\tapplication/x-www-form-urlencoded\nx-tab\ta\tb\n\nBASE_URL\thttps://example.com\n\nname=%E6%97%A5\n\nraw",
  )
  let req = decode_request(data)
  assert_eq(req.verb, "POST")
  assert_eq((req.host, req.path, req.raw_query), ("h.example", "/a b", "x=1"))
  assert_eq(req.headers.get("x-tab"), Some("a\tb"))
  assert_eq(req.env.get("BASE_URL"), Some("https://example.com"))
  // The body is everything after the head, newlines and all.
  assert_eq(req.text(), "name=%E6%97%A5\n\nraw")
  let req = decode_request(@utf8.encode("GET\n/\n\n\n"))
  assert_eq(
    (req.path, req.headers.fields.length(), req.body.length()),
    ("/", 0, 0),
  )
}

///|
test "decode_request rejects a truncated request" {
  for s in ["", "GET\n/\n", "GET\n/\n\n", "GET\nhttp://h/%zz\n\n\n"] {
    try decode_request(@utf8.encode(s)) catch {
      _ => ()
    } noraise {
      _ => fail("\{s.escape()} must raise")
    }
  }
}

///|
test "encode_head" {
  let res = @http.Response::text(201, "ok")..header("set-cookie", value="a=1")
  assert_eq(
    encode_head(res),
    "201\ncontent-type\ttext/plain; charset=utf-8\nset-cookie\ta=1\n\n",
  )
}

///|
test "encode_head neutralizes newlines in values and drops bad names" {
  // A redirect to a decoded ?to=/%0Aset-cookie%09session=x must not
  // become a second field, nor end the head.
  let res = @http.Response::redirect(302, "/\nset-cookie\tsession=x\r\n\nbody")
  res.header("x-tab", value="a\tb")
  res.header("bad name", value="1")
  res.header("bad\nname", value="1")
  res.header("", value="1")
  assert_eq(
    encode_head(res),
    "302\nlocation\t/ set-cookie\tsession=x   body\nx-tab\ta\tb\n\n",
  )
}
