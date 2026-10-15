// The derived Eq and Debug methods are declared here because the compiler
// asks for it (warning implicit_impl_as_method). They are not deprecated
// as in moonbitlang/core: the package is only used in this repository.

///|
pub extend Tag with Eq::{equal, not_equal}

///|
pub extend Tag with Debug::{to_repr}

///|
pub extend AttrName with Eq::{equal, not_equal}

///|
pub extend AttrName with Debug::{to_repr}

///|
pub extend Node with Eq::{equal, not_equal}

///|
pub extend Node with Debug::{to_repr}
