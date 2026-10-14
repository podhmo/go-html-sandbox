package main

// css is inlined into every page by layout. Plain CSS, no build step.
// Written mobile-first: base rules target narrow screens and the min-width
// media query only adds room on wider ones.
const css = `
:root {
  color-scheme: light dark;
  --fg: #1f2328;
  --muted: #59636e;
  --bg: #ffffff;
  --surface: #f6f8fa;
  --border: #d1d9e0;
  --accent: #2563eb;
  --space: 1rem;
  --radius: 0.5rem;
}
@media (prefers-color-scheme: dark) {
  :root {
    --fg: #e6edf3;
    --muted: #9198a1;
    --bg: #0d1117;
    --surface: #151b23;
    --border: #3d444d;
    --accent: #6ea8fe;
  }
}
*, *::before, *::after { box-sizing: border-box; }
html { -webkit-text-size-adjust: 100%; text-size-adjust: 100%; }
body {
  margin: 0;
  color: var(--fg);
  background: var(--bg);
  font: 1rem/1.7 system-ui, -apple-system, "Hiragino Sans", sans-serif;
  overflow-wrap: anywhere;
}
header, main, footer {
  max-inline-size: 40rem;
  margin-inline: auto;
  padding-inline: max(var(--space), env(safe-area-inset-left), env(safe-area-inset-right));
}
header { padding-block: var(--space); border-block-end: 1px solid var(--border); }
main { padding-block: var(--space) calc(var(--space) * 2); }
footer {
  padding-block: var(--space) max(var(--space), env(safe-area-inset-bottom));
  color: var(--muted);
  font-size: 0.875rem;
}
a { color: var(--accent); }
.site { font-weight: 700; text-decoration: none; color: var(--fg); }
h1, h2, h3 { line-height: 1.3; margin-block: 1.5em 0.5em; }
h1 { font-size: clamp(1.5rem, 1.2rem + 1.5vw, 2rem); }
h2 { font-size: clamp(1.25rem, 1.1rem + 0.8vw, 1.5rem); }
h3 { font-size: 1.125rem; }
main > h1:first-child, article > section:first-of-type > h1 { margin-block-start: 0.5em; }
time { color: var(--muted); font-size: 0.875rem; }
ul { padding-inline-start: 1.25em; }
pre {
  overflow-x: auto;
  padding: var(--space);
  background: var(--surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  font: 0.875rem/1.5 ui-monospace, SFMono-Regular, Menlo, monospace;
  overflow-wrap: normal;
  tab-size: 4;
}
.posts { list-style: none; padding: 0; margin: 0; }
.posts a {
  display: flex;
  flex-direction: column;
  justify-content: center;
  min-block-size: 2.75rem;
  padding-block: 0.75rem;
  border-block-end: 1px solid var(--border);
  text-decoration: none;
  color: var(--fg);
}
.posts .title { font-weight: 600; }
@media (min-width: 40rem) {
  :root { --space: 1.5rem; }
  .posts a { flex-direction: row; justify-content: space-between; align-items: baseline; gap: var(--space); }
}
`
