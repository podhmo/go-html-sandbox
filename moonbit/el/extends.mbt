// The derived Eq and Debug are meant for == and assert_eq, not as methods;
// these declarations mark the implicitly promoted methods as unwanted
// (warning implicit_impl_as_method), as moonbitlang/core does.

///|
#deprecated("Use == and != instead")
pub extend Tag with Eq::{equal, not_equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Tag with Debug::{to_repr}

///|
#deprecated("Use == and != instead")
pub extend AttrName with Eq::{equal, not_equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend AttrName with Debug::{to_repr}

///|
#deprecated("Use == and != instead")
pub extend Node with Eq::{equal, not_equal}

///|
#deprecated("Use Debug::to_repr instead")
pub extend Node with Debug::{to_repr}
