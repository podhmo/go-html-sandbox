// Loading the Wasm modules with the JS string builtins, shared by the
// page and the Workers.
const options = { builtins: ["js-string"], importedStringConstants: "_" };

// load instantiates build/<name>.wasm with imports and returns its exports.
export async function load(name, imports = {}) {
  const url = new URL(`./build/${name}.wasm`, import.meta.url);
  const { instance } = await WebAssembly.instantiateStreaming(fetch(url), imports, options);
  return instance.exports;
}
