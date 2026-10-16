// The Worker for the echo example (./echo.mbt), through the adapter of
// ../../pkg/http/wasm.
import wasm from "../../_build/wasm-gc/release/build/examples/echo/echo.wasm";
import { wasmApp } from "../../pkg/http/wasm/adapter.mjs";

export default wasmApp(wasm);
