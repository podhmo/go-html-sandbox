name = "podhmo/blog"

version = "0.1.0"

readme = "README.md"

repository = "https://github.com/podhmo/html-sandbox"

license = "MIT"

keywords = [ ]

preferred_target = "wasm-gc"

description = "The blog of html-sandbox, served from Wasm on Cloudflare Workers."

import {
  "moonbitlang/async@0.22.5",
}

// Opt-in warnings that point at rewrites (see the modernize report in
// docs/sketch/ja/moonbit-modernize.md). unnecessary_annotation stays off
// because `@pkg.` qualifiers are kept on purpose, missing_doc because
// private helpers go undocumented, and prefer_readonly_array /
// prefer_fixed_array because the ports keep Go's slices as Array.

warnings = "+unnecessary_view_op+unqualified_record+unqualified_local_using+unused_optional_argument+unused_default_value+result_error_return+ambiguous_range_direction+deprecated_for_in_method"
