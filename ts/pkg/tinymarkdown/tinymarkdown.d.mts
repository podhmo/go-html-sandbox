// The types of tinymarkdown.mjs, which moon generates with any.
import type { Document, Inline } from "./tinymarkdown.ts";

export function parse(src: string): Document;
export function inlines(s: string): Inline[];
