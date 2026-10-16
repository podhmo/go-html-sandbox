// The parser service: a Worker holding parser.wasm. It takes Markdown
// from the page and hands the JSON to the html service over the
// MessagePort the page gave it, so the page never sees the JSON.
import { load } from "./wasm.mjs";

// The handler is set before the Wasm is loaded, so that no message is
// missed; the work waits on the load.
const loaded = load("parser");
let html;
self.onmessage = async ({ data }) => {
  if (data.port) {
    html = data.port;
    return;
  }
  const { parse } = await loaded;
  html.postMessage({ id: data.id, json: parse(data.md) });
};
