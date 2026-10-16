// The Worker for the echo example (./echo.mbt), through the adapter of
// ../../http/wasm.
import wasm from "./build/echo.wasm";
import { wasmApp } from "../../http/wasm/adapter.mjs";

export default wasmApp(wasm);
