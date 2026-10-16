import wasm from "./build/v0.wasm";
const body = { "/": "x".repeat(1732), big: "x".repeat(36670) };
export default {
  async fetch(request) {
    const p = new URL(request.url).pathname;
    return new Response(p === "/" ? body["/"] : body.big, { status: 200, headers: { "content-type": "text/html; charset=utf-8" } });
  },
};
