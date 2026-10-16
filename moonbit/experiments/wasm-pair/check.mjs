// `make check-browser`: open /?check in headless Chrome in real time (not
// --virtual-time-budget, which would fake the timer the check reads),
// through the DevTools protocol, and print what the page wrote.
// Usage: node check.mjs <chrome> <url>
import { spawn } from "node:child_process";
import { mkdtempSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

const [chrome, url] = process.argv.slice(2);
const port = 9333;
const proc = spawn(chrome, [
  "--headless=new", "--disable-gpu", `--remote-debugging-port=${port}`,
  `--user-data-dir=${mkdtempSync(join(tmpdir(), "wasm-pair-"))}`, "about:blank",
], { stdio: "ignore" });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
try {
  let targets;
  for (let i = 0; i < 50 && !targets; i++) {
    await sleep(200);
    targets = await fetch(`http://127.0.0.1:${port}/json`).then((r) => r.json()).catch(() => undefined);
  }
  const page = targets.find((t) => t.type === "page");
  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((r) => ws.addEventListener("open", r, { once: true }));
  let id = 0;
  const send = (method, params = {}) => new Promise((resolve) => {
    const me = ++id;
    ws.addEventListener("message", function on({ data }) {
      const msg = JSON.parse(data);
      if (msg.id !== me) return;
      ws.removeEventListener("message", on);
      resolve(msg.result);
    });
    ws.send(JSON.stringify({ id: me, method, params }));
  });
  await send("Page.navigate", { url });
  for (let i = 0; i < 300; i++) {
    await sleep(100);
    const { result } = await send("Runtime.evaluate", {
      expression: `[document.getElementById("status")?.textContent, document.getElementById("check")?.textContent].join("\\n")`,
    });
    if (result.value?.includes("workers:")) {
      console.log(result.value);
      break;
    }
  }
  ws.close();
} finally {
  proc.kill();
}
