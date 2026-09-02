import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import spaceship_helm/cookie

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn get_cookie_from_request_test() {
  let req =
    request.new()
    |> request.set_header("cookie", "session_id=abc123; username=alice")

  let result = cookie.get(req, "session_id")
  assert result == Some("abc123")
}

pub fn get_cookie_not_found_test() {
  let req =
    request.new()
    |> request.set_header("cookie", "session_id=abc123")

  let result = cookie.get(req, "username")
  assert result == None
}

pub fn get_cookie_no_header_test() {
  let req = request.new()

  let result = cookie.get(req, "session_id")
  assert result == None
}

pub fn get_all_cookies_test() {
  let req =
    request.new()
    |> request.set_header("cookie", "session_id=abc123; username=alice")

  let result = cookie.get_all(req)
  assert result == [#("session_id", "abc123"), #("username", "alice")]
}

pub fn set_cookie_test() {
  let resp =
    response.new(200)
    |> response.set_body(<<"Hello":utf8>>)
    |> cookie.set("session_id", "abc123", 3600)

  let set_cookie_header =
    resp.headers
    |> list.find(fn(h) { h.0 == "set-cookie" })
    |> fn(r) {
      case r {
        Ok(#(_, value)) -> value
        Error(_) -> ""
      }
    }

  assert set_cookie_header |> string.contains("session_id=abc123")
  assert set_cookie_header |> string.contains("Max-Age=3600")
  assert set_cookie_header |> string.contains("HttpOnly")
  assert set_cookie_header |> string.contains("Secure")
}

pub fn delete_cookie_test() {
  let resp =
    response.new(200)
    |> response.set_body(<<"Hello":utf8>>)
    |> cookie.delete("session_id")

  let set_cookie_header =
    resp.headers
    |> list.find(fn(h) { h.0 == "set-cookie" })
    |> fn(r) {
      case r {
        Ok(#(_, value)) -> value
        Error(_) -> ""
      }
    }

  assert set_cookie_header |> string.contains("session_id=")
  assert set_cookie_header |> string.contains("Max-Age=0")
}
