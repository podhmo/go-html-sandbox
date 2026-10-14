# Mobile-first without a build step

The stylesheet is a Go string constant inlined into every page.
It is written for narrow screens first and only adds room on wider ones.

## Techniques used

- A single min-width media query instead of max-width overrides.
- Custom properties for colors and spacing.
- clamp() for heading sizes.
- prefers-color-scheme for dark mode.
- env(safe-area-inset-*) to keep clear of notches.
- Tap targets of at least 44px in the post list.
