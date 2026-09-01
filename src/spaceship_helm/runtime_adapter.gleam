import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/javascript/promise.{type Promise}

/// Opaque platform request value supplied by a runtime shim.
pub type PlatformRequest

/// Opaque platform response value returned by a runtime shim.
pub type PlatformResponse

/// Opaque Node.js ServerResponse value.
pub type NodeServerResponse

/// Convert a Cloudflare Workers Request to a Gleam request.
@external(javascript, "../ffi/runtimes/cloudflare.mjs", "toGleamRequest")
pub fn cloudflare_to_gleam_request(
  request: PlatformRequest,
) -> Promise(Request(BitArray))

/// Convert a Gleam response to a Cloudflare Workers Response.
@external(javascript, "../ffi/runtimes/cloudflare.mjs", "toPlatformResponse")
pub fn cloudflare_to_platform_response(
  response: Response(BitArray),
) -> PlatformResponse

/// Convert a Node.js IncomingMessage to a Gleam request.
@external(javascript, "../ffi/runtimes/node.mjs", "toGleamRequest")
pub fn node_to_gleam_request(
  request: PlatformRequest,
) -> Promise(Request(BitArray))

/// Write a Gleam response to a Node.js ServerResponse.
@external(javascript, "../ffi/runtimes/node.mjs", "toPlatformResponse")
pub fn node_to_platform_response(
  response: Response(BitArray),
  server_response: NodeServerResponse,
) -> Nil

/// Convert a Bun Request to a Gleam request.
@external(javascript, "../ffi/runtimes/bun.mjs", "toGleamRequest")
pub fn bun_to_gleam_request(
  request: PlatformRequest,
) -> Promise(Request(BitArray))

/// Convert a Gleam response to a Bun Response.
@external(javascript, "../ffi/runtimes/bun.mjs", "toPlatformResponse")
pub fn bun_to_platform_response(
  response: Response(BitArray),
) -> PlatformResponse

/// Convert a Deno Request to a Gleam request.
@external(javascript, "../ffi/runtimes/deno.mjs", "toGleamRequest")
pub fn deno_to_gleam_request(
  request: PlatformRequest,
) -> Promise(Request(BitArray))

/// Convert a Gleam response to a Deno Response.
@external(javascript, "../ffi/runtimes/deno.mjs", "toPlatformResponse")
pub fn deno_to_platform_response(
  response: Response(BitArray),
) -> PlatformResponse
