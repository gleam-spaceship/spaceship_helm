import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import spaceship_helm/types.{type Context}

/// Get a path parameter by name
pub fn param(ctx: Context, name: String) -> String {
  dict.get(ctx.params, name) |> result.unwrap("")
}

/// Get a query parameter by name, returns None if not present
pub fn query(ctx: Context, name: String) -> Option(String) {
  case dict.get(ctx.query, name) {
    Ok(value) -> option.Some(value)
    Error(_) -> option.None
  }
}

/// Get a query parameter with a default value
pub fn query_with_default(
  ctx: Context,
  name: String,
  default: String,
) -> String {
  dict.get(ctx.query, name) |> result.unwrap(default)
}

/// Get a header value
pub fn header(ctx: Context, name: String) -> Option(String) {
  // gleam_http Request has headers as a List of tuples, not a Dict
  // We need to find the header manually
  ctx.req.headers
  |> list.find(fn(h) {
    let #(key, _) = h
    key == name
  })
  |> fn(result) {
    case result {
      Ok(#(_, value)) -> option.Some(value)
      Error(_) -> option.None
    }
  }
}

/// Get the request body
pub fn body(ctx: Context) -> BitArray {
  ctx.req.body
}

/// Get a string parameter, returns None if not present
pub fn get_param(ctx: Context, name: String) -> Option(String) {
  case dict.get(ctx.params, name) {
    Ok(value) -> option.Some(value)
    Error(_) -> option.None
  }
}

/// Get all path parameters
pub fn params(ctx: Context) -> Dict(String, String) {
  ctx.params
}

/// Get all query parameters
pub fn query_params(ctx: Context) -> Dict(String, String) {
  ctx.query
}

/// Parse query string from request
pub fn parse_query(query_string: String) -> Dict(String, String) {
  case query_string {
    "" -> dict.new()
    _ -> {
      query_string
      |> string.split("&")
      |> list.fold(dict.new(), fn(acc, pair) {
        case string.split(pair, "=") {
          [key, value] -> dict.insert(acc, key, value)
          [key] -> dict.insert(acc, key, "")
          _ -> acc
        }
      })
    }
  }
}
