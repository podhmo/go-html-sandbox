// The Worker for the echo example (./echo.mbt), through the adapter of
// ../../pkg/http/wasm.
import wasm from "./build/echo.wasm";
import { wasmApp } from "../../pkg/http/wasm/adapter.mjs";

export default wasmApp(wasm);
