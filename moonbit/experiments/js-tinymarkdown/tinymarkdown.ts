// The TS port's API (ts/pkg/tinymarkdown/tinymarkdown.ts) over the js
// build of MoonBit's tinymarkdown: the same types, with parse and inlines
// from build/tinymarkdown.mjs. vitest.config.mjs and vite.config.mjs put
// this file in place of the TS port.
import type { Document, Inline } from "../../../ts/pkg/tinymarkdown/tinymarkdown.ts";
import * as moonbit from "./build/tinymarkdown.mjs";

export type * from "../../../ts/pkg/tinymarkdown/tinymarkdown.ts";

export const parse: (src: string) => Document = moonbit.parse;
export const inlines: (s: string) => Inline[] = moonbit.inlines;
