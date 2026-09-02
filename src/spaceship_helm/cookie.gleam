/// Cookie helpers for reading and writing HTTP cookies.
///
/// # Usage
///
/// ```gleam
/// // In handler
/// let session_id = cookie.get(ctx, "session_id")
/// let response = cookie.set(response, "session_id", "abc123", 3600)
/// ```
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

/// Get a cookie value from the request by name.
///
/// Returns Some(value) if found, None otherwise.
pub fn get(req: Request(body), name: String) -> Option(String) {
  case req.headers |> list.find(fn(h) { h.0 == "cookie" }) {
    Ok(#(_, header_value)) -> parse_cookie_header(header_value, name)
    Error(_) -> None
  }
}

/// Get all cookies from the request.
///
/// Returns a list of (name, value) tuples.
pub fn get_all(req: Request(body)) -> List(#(String, String)) {
  case req.headers |> list.find(fn(h) { h.0 == "cookie" }) {
    Ok(#(_, header_value)) -> parse_all_cookies(header_value)
    Error(_) -> []
  }
}

/// Set a cookie on the response with default settings.
///
/// The cookie will be available for the path "/" and expires after max_age seconds.
pub fn set(
  resp: Response(body),
  name: String,
  value: String,
  max_age: Int,
) -> Response(body) {
  set_with_options(
    resp,
    name,
    value,
    CookieOptions(
      path: "/",
      max_age: max_age,
      http_only: True,
      secure: True,
      same_site: "Lax",
    ),
  )
}

/// Set a cookie with full options.
pub fn set_with_options(
  resp: Response(body),
  name: String,
  value: String,
  options: CookieOptions,
) -> Response(body) {
  let cookie_value = name <> "=" <> value
  let path_attr = "; Path=" <> options.path
  let max_age_attr = "; Max-Age=" <> int_to_string(options.max_age)
  let http_only_attr = case options.http_only {
    True -> "; HttpOnly"
    False -> ""
  }
  let secure_attr = case options.secure {
    True -> "; Secure"
    False -> ""
  }
  let same_site_attr = "; SameSite=" <> options.same_site

  let cookie_str =
    cookie_value
    <> path_attr
    <> max_age_attr
    <> http_only_attr
    <> secure_attr
    <> same_site_attr

  resp
  |> response.set_header("set-cookie", cookie_str)
}

/// Delete a cookie by setting it with max-age 0.
pub fn delete(resp: Response(body), name: String) -> Response(body) {
  let cookie_value = name <> "="
  let cookie_str = cookie_value <> "; Path=/; Max-Age=0"
  resp
  |> response.set_header("set-cookie", cookie_str)
}

/// Options for setting cookies.
pub type CookieOptions {
  CookieOptions(
    path: String,
    max_age: Int,
    http_only: Bool,
    secure: Bool,
    same_site: String,
  )
}

/// Default cookie options (http_only, secure, SameSite=Lax, path="/").
pub fn default_options() -> CookieOptions {
  CookieOptions(
    path: "/",
    max_age: 86_400,
    http_only: True,
    secure: True,
    same_site: "Lax",
  )
}

// ── Internal ──────────────────────────────────────────────────

/// Parse a specific cookie value from the Cookie header string.
fn parse_cookie_header(header: String, name: String) -> Option(String) {
  header
  |> string.split(";")
  |> list.map(fn(s) { string.trim(s) })
  |> list.find(fn(s) {
    case string.split(s, "=") {
      [n, _] -> n == name
      _ -> False
    }
  })
  |> fn(result) {
    case result {
      Ok(pair) -> {
        case string.split(pair, "=") {
          [_, value] -> Some(value)
          _ -> None
        }
      }
      Error(_) -> None
    }
  }
}

/// Parse all cookies from the Cookie header string.
fn parse_all_cookies(header: String) -> List(#(String, String)) {
  header
  |> string.split(";")
  |> list.map(fn(s) { string.trim(s) })
  |> list.filter_map(fn(s) {
    case string.split(s, "=") {
      [name, value] -> Ok(#(name, value))
      _ -> Error(Nil)
    }
  })
}

/// Convert an integer to string.
fn int_to_string(n: Int) -> String {
  do_int_to_string(n)
}

@external(erlang, "erlang", "integer_to_binary")
@external(javascript, "./ffi/cookie.mjs", "intToString")
fn do_int_to_string(n: Int) -> String
