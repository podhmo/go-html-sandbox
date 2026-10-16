// Fetches every page linked from / and /docs/ on two blogs, and reports the
// paths whose status or body differ. Usage: node crawl.mjs URL_A URL_B
const [a, b] = process.argv.slice(2);
const seen = new Set();
const queue = ["/", "/docs/", "/no-such-page"];
let diffs = 0;
while (queue.length > 0) {
  const path = queue.shift();
  if (seen.has(path)) continue;
  seen.add(path);
  const [ra, rb] = await Promise.all([fetch(a + path), fetch(b + path)]);
  const [ta, tb] = await Promise.all([ra.text(), rb.text()]);
  if (ra.status !== rb.status || ta !== tb) {
    diffs++;
    console.log(`differs: ${path} (${ra.status} ${rb.status})`);
  }
  for (const m of ta.matchAll(/href="(\/(?:posts|docs)\/[^"#?]*)"/g)) queue.push(m[1]);
}
console.log(`${seen.size} paths, ${diffs} differ`);
process.exitCode = diffs > 0 ? 1 : 0;
