// The Worker for the spike: `make dev`.
import wasm from "./build/proxy.wasm";
import { jspiApp } from "./adapter.mjs";

export default jspiApp(wasm);
