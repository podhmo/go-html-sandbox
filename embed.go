// Package sandbox embeds the repository's own documents so that examples
// can serve them. It lives at the repository root because go:embed cannot
// reach files above the embedding package's directory.
package sandbox

import "embed"

// Docs holds TODO.md and everything under docs/.
//
//go:embed TODO.md docs
var Docs embed.FS
