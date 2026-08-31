import gleam/dynamic
import gleam/option.{type Option, None, Some}

/// Environment variable storage.
/// This is populated by the platform shim at startup.
pub type Env {
  Env(vars: dynamic.Dynamic)
}

/// Get the global environment instance.
pub fn get_global_env() -> Option(Env) {
  do_get_global_env()
}

/// Set the global environment instance.
/// Called by the platform shim at startup.
pub fn set_global_env(env: Env) -> Nil {
  do_set_global_env(env)
}

/// Initialize the environment with platform-specific values.
/// Called by the platform shim at startup.
pub fn init(vars: dynamic.Dynamic) -> Nil {
  set_global_env(Env(vars:))
}

/// Get an environment variable by name.
/// Returns None if the variable is not set.
pub fn get(name: String) -> Option(String) {
  case get_global_env() {
    Some(env) -> do_get(env.vars, name)
    None -> do_get_from_platform(name)
  }
}

/// Get an environment variable by name with a default value.
/// Returns the default if the variable is not set.
pub fn get_or(name: String, default: String) -> String {
  case get(name) {
    Some(value) -> value
    None -> default
  }
}

/// Get an environment variable by name, or panic if not set.
/// Use this only for required environment variables.
pub fn get_required(name: String) -> String {
  case get(name) {
    Some(value) -> value
    None -> {
      let msg = "Required environment variable not set: " <> name
      panic as msg
    }
  }
}

/// Check if an environment variable is set.
pub fn has(name: String) -> Bool {
  case get(name) {
    Some(_) -> True
    None -> False
  }
}

/// Get all environment variables as a list of key-value pairs.
/// Note: This depends on the platform implementation.
pub fn all() -> List(#(String, String)) {
  case get_global_env() {
    Some(env) -> do_all(env.vars)
    None -> do_all_from_platform()
  }
}

// ── Platform-specific FFI ────────────────────────────────────

/// Get the global environment instance.
@external(erlang, "./ffi/env.erl", "get_global_env")
@external(javascript, "./ffi/env.mjs", "get_global_env")
fn do_get_global_env() -> Option(Env)

/// Set the global environment instance.
@external(erlang, "./ffi/env.erl", "set_global_env")
@external(javascript, "./ffi/env.mjs", "set_global_env")
fn do_set_global_env(env: Env) -> Nil

/// Get an environment variable from the platform-specific store.
@external(erlang, "./ffi/env.erl", "get_env")
@external(javascript, "./ffi/env.mjs", "get_env")
fn do_get(vars: dynamic.Dynamic, name: String) -> Option(String)

/// Get all environment variables from the platform-specific store.
@external(erlang, "./ffi/env.erl", "get_all_env")
@external(javascript, "./ffi/env.mjs", "get_all_env")
fn do_all(vars: dynamic.Dynamic) -> List(#(String, String))

/// Get an environment variable directly from the platform.
@external(erlang, "./ffi/env.erl", "get_env_from_platform")
@external(javascript, "./ffi/env.mjs", "get_env_from_platform")
fn do_get_from_platform(name: String) -> Option(String)

/// Get all environment variables directly from the platform.
@external(erlang, "./ffi/env.erl", "get_all_from_platform")
@external(javascript, "./ffi/env.mjs", "get_all_from_platform")
fn do_all_from_platform() -> List(#(String, String))
