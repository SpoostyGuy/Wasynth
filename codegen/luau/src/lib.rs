pub static RUNTIME: &str = include_str!("../runtime/runtime.luau");
pub static EXPORT_RUNTIME: &str = include_str!("../runtime/export_runtime.luau");

pub use translator::{from_inst_list, from_module_typed, from_module_untyped};

mod analyzer;
mod backend;
mod translator;
