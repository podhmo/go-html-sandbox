export default { fetch() { return new Response(JSON.stringify({ Suspending: typeof WebAssembly.Suspending, promising: typeof WebAssembly.promising })); } };
