// Types for spaceship_helm
// This module is used to avoid circular dependencies

import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}

pub type Context {
  Context(
    req: Request(BitArray),
    params: Dict(String, String),
    query: Dict(String, String),
    extra: Dict(String, Dynamic),
  )
}

pub type Handler =
  fn(Context) -> Response(BitArray)

pub type Middleware =
  fn(Context, fn(Context) -> Response(BitArray)) -> Response(BitArray)

pub type Route {
  Route(path: List(String), handler: Handler, middleware: List(Middleware))
}
