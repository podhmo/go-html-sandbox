// The html service: a Worker holding html.wasm. It takes JSON from the
// parser service over a MessagePort and answers the page with the HTML.
import { load } from "./wasm.mjs";

// As in parser-worker.mjs, the handlers do not wait for the Wasm to be set.
const loaded = load("html");
self.onmessage = ({ data }) => {
  data.port.onmessage = async ({ data }) => {
    const { render } = await loaded;
    self.postMessage({ id: data.id, html: render(data.json) });
  };
};
