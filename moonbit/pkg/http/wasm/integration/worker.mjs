// The Worker for the stub app (./echo.mbt), through ../adapter.mjs.
import wasm from "../../../../_build/wasm-gc/release/build/pkg/http/wasm/integration/integration.wasm";
import { wasmApp } from "../adapter.mjs";

export default wasmApp(wasm);
