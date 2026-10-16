// The ts blog's Vite config (ts/examples/blog/vite.config.ts) with the TS
// port of tinymarkdown swapped for the MoonBit build (swap.mjs), building
// into build/blog/ rather than the blog's dist/.
import { swapTinymarkdown } from "./swap.mjs";
import blog from "../../../ts/examples/blog/vite.config.ts";

export default {
  ...blog,
  root: `${import.meta.dirname}/../../../ts/examples/blog`,
  plugins: [swapTinymarkdown(), ...blog.plugins],
  build: { ...blog.build, outDir: `${import.meta.dirname}/build/blog` },
};
