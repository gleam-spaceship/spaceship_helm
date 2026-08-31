import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/string
import spaceship_helm/types.{type Context, type Middleware}

/// CORS middleware
pub fn cors() -> Middleware {
  fn(ctx, next) {
    let resp = next(ctx)
    resp
    |> response.set_header("access-control-allow-origin", "*")
    |> response.set_header(
      "access-control-allow-methods",
      "GET, POST, PUT, DELETE, PATCH, OPTIONS",
    )
    |> response.set_header(
      "access-control-allow-headers",
      "content-type, authorization",
    )
    |> response.set_header("access-control-max-age", "86400")
  }
}

/// Logger middleware — logs method, path, status, and duration
pub fn logger(log_fn: fn(String) -> Nil) -> Middleware {
  fn(ctx: Context, next) {
    let method = string.inspect(ctx.req.method)
    let path = ctx.req.path
    let resp: Response(BitArray) = next(ctx)
    let status = resp.status

    // Log using provided function
    log_fn(string.concat([method, " ", path, " ", int.to_string(status)]))
    resp
  }
}

/// Middleware that adds a custom header
pub fn add_header(name: String, value: String) -> Middleware {
  fn(ctx: Context, next) {
    let resp = next(ctx)
    response.set_header(resp, name, value)
  }
}

/// Middleware that runs only if condition is true
pub fn when(condition: Bool, mw: Middleware) -> Middleware {
  fn(ctx: Context, next) {
    case condition {
      True -> mw(ctx, next)
      False -> next(ctx)
    }
  }
}

/// Compose multiple middleware into one
pub fn compose(middlewares: List(Middleware)) -> Middleware {
  fn(ctx: Context, next) {
    middlewares
    |> list.reverse
    |> list.fold(next, fn(acc, mw) { fn(ctx) { mw(ctx, acc) } })
    |> fn(run) { run(ctx) }
  }
}
