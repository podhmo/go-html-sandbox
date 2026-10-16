import fs from "node:fs";
const m = new WebAssembly.Module(fs.readFileSync(process.argv[2]));
console.log("exports", WebAssembly.Module.exports(m));
console.log("imports", WebAssembly.Module.imports(m));
