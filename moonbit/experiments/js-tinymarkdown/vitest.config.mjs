// ts/'s tests, the tinymarkdown port's and the blog's, with the TS port
// swapped for the MoonBit build (swap.mjs). Imports nothing from ts/, so
// it loads from here.
import { swapTinymarkdown } from "./swap.mjs";

export default {
  root: `${import.meta.dirname}/../../../ts`,
  plugins: [swapTinymarkdown()],
};
