import gleam/http/response.{type Response}
import gleam/json.{type Json}

/// Create a text response
pub fn text(content: String) -> Response(BitArray) {
  response.new(200)
  |> response.set_body(<<content:utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}

/// Create an HTML response
pub fn html(content: String) -> Response(BitArray) {
  response.new(200)
  |> response.set_body(<<content:utf8>>)
  |> response.set_header("content-type", "text/html; charset=utf-8")
}

/// Create a JSON response
pub fn json(data: Json) -> Response(BitArray) {
  let body = json.to_string(data)
  response.new(200)
  |> response.set_body(<<body:utf8>>)
  |> response.set_header("content-type", "application/json; charset=utf-8")
}

/// Create a redirect response
pub fn redirect(url: String) -> Response(BitArray) {
  response.new(302)
  |> response.set_body(<<>>)
  |> response.set_header("location", url)
}

/// Create a permanent redirect response
pub fn redirect_permanent(url: String) -> Response(BitArray) {
  response.new(301)
  |> response.set_body(<<>>)
  |> response.set_header("location", url)
}

/// Set status code on a response
pub fn with_status(
  resp: Response(BitArray),
  status: Int,
) -> Response(BitArray) {
  response.new(status)
  |> response.set_body(resp.body)
}

/// Set a header on a response
pub fn with_header(
  resp: Response(BitArray),
  name: String,
  value: String,
) -> Response(BitArray) {
  response.set_header(resp, name, value)
}

/// Create a no-content response (204)
pub fn no_content() -> Response(BitArray) {
  response.new(204)
  |> response.set_body(<<>>)
}

/// Create a bad request response (400)
pub fn bad_request(msg: String) -> Response(BitArray) {
  response.new(400)
  |> response.set_body(<<msg:utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}

/// Create an unauthorized response (401)
pub fn unauthorized() -> Response(BitArray) {
  response.new(401)
  |> response.set_body(<<"Unauthorized":utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}

/// Create a forbidden response (403)
pub fn forbidden() -> Response(BitArray) {
  response.new(403)
  |> response.set_body(<<"Forbidden":utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}

/// Create a not found response (404)
pub fn not_found() -> Response(BitArray) {
  response.new(404)
  |> response.set_body(<<"Not Found":utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}

/// Create an internal server error response (500)
pub fn internal_server_error() -> Response(BitArray) {
  response.new(500)
  |> response.set_body(<<"Internal Server Error":utf8>>)
  |> response.set_header("content-type", "text/plain; charset=utf-8")
}
