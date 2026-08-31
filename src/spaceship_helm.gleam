import gleam/dict.{type Dict}
import gleam/http.{
  Connect, Delete, Get, Head, Options, Other, Patch, Post, Put, Trace,
}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import spaceship_helm/context
import spaceship_helm/internal/router
import spaceship_helm/types.{
  type Context, type Handler, type Middleware, type Route,
  Route as RouteConstructor,
}

pub type App {
  App(
    get: List(Route),
    post: List(Route),
    put: List(Route),
    delete: List(Route),
    patch: List(Route),
    head: List(Route),
    options: List(Route),
    custom: Dict(String, List(Route)),
    not_found: Handler,
    middleware: List(Middleware),
  )
}

/// Create a new app
pub fn new() -> App {
  App(
    get: [],
    post: [],
    put: [],
    delete: [],
    patch: [],
    head: [],
    options: [],
    custom: dict.new(),
    not_found: fn(_ctx) {
      response.new(404)
      |> response.set_body(<<"Not Found":utf8>>)
    },
    middleware: [],
  )
}

/// Add global middleware
pub fn middleware(app: App, mw: Middleware) -> App {
  App(..app, middleware: [mw, ..app.middleware])
}

/// Register a GET route
pub fn get(app: App, path: String, handler: Handler) -> App {
  add_route(app, "GET", path, handler)
}

/// Register a POST route
pub fn post(app: App, path: String, handler: Handler) -> App {
  add_route(app, "POST", path, handler)
}

/// Register a PUT route
pub fn put(app: App, path: String, handler: Handler) -> App {
  add_route(app, "PUT", path, handler)
}

/// Register a DELETE route
pub fn delete(app: App, path: String, handler: Handler) -> App {
  add_route(app, "DELETE", path, handler)
}

/// Register a PATCH route
pub fn patch(app: App, path: String, handler: Handler) -> App {
  add_route(app, "PATCH", path, handler)
}

/// Register a HEAD route
pub fn head(app: App, path: String, handler: Handler) -> App {
  add_route(app, "HEAD", path, handler)
}

/// Register an OPTIONS route
pub fn options(app: App, path: String, handler: Handler) -> App {
  add_route(app, "OPTIONS", path, handler)
}

/// Register a route with custom method
pub fn on(app: App, method: String, path: String, handler: Handler) -> App {
  add_route(app, method, path, handler)
}

/// Group routes under a prefix
pub fn group(app: App, prefix: String, routes: fn(App) -> App) -> App {
  let temp_app = new()
  let with_routes = routes(temp_app)

  let app = add_routes_with_prefix(app, prefix, with_routes.get, "GET")
  let app = add_routes_with_prefix(app, prefix, with_routes.post, "POST")
  let app = add_routes_with_prefix(app, prefix, with_routes.put, "PUT")
  let app = add_routes_with_prefix(app, prefix, with_routes.delete, "DELETE")
  let app = add_routes_with_prefix(app, prefix, with_routes.patch, "PATCH")
  let app = add_routes_with_prefix(app, prefix, with_routes.head, "HEAD")
  let app = add_routes_with_prefix(app, prefix, with_routes.options, "OPTIONS")
  app
}

/// Set custom not-found handler
pub fn not_found(app: App, handler: Handler) -> App {
  App(..app, not_found: handler)
}

/// Convert app to a fetch handler for JS runtimes
pub fn to_fetch(app: App) -> fn(Request(BitArray)) -> Response(BitArray) {
  fn(req) { handle_request(app, req) }
}

// --- Internal ---

fn add_route(app: App, method: String, path: String, handler: Handler) -> App {
  let path_segments = parse_path(path)
  let route =
    RouteConstructor(
      path: path_segments,
      handler: handler,
      middleware: app.middleware,
    )

  case method {
    "GET" -> App(..app, get: [route, ..app.get])
    "POST" -> App(..app, post: [route, ..app.post])
    "PUT" -> App(..app, put: [route, ..app.put])
    "DELETE" -> App(..app, delete: [route, ..app.delete])
    "PATCH" -> App(..app, patch: [route, ..app.patch])
    "HEAD" -> App(..app, head: [route, ..app.head])
    "OPTIONS" -> App(..app, options: [route, ..app.options])
    _ -> {
      let existing = dict.get(app.custom, method) |> result.unwrap([])
      App(..app, custom: dict.insert(app.custom, method, [route, ..existing]))
    }
  }
}

fn add_routes_with_prefix(
  app: App,
  prefix: String,
  routes: List(Route),
  method: String,
) -> App {
  let prefix_segments = parse_path(prefix)
  list.fold(routes, app, fn(acc, route) {
    let full_path = list.append(prefix_segments, route.path)
    let new_route = RouteConstructor(..route, path: full_path)
    case method {
      "GET" -> App(..acc, get: [new_route, ..acc.get])
      "POST" -> App(..acc, post: [new_route, ..acc.post])
      "PUT" -> App(..acc, put: [new_route, ..acc.put])
      "DELETE" -> App(..acc, delete: [new_route, ..acc.delete])
      "PATCH" -> App(..acc, patch: [new_route, ..acc.patch])
      "HEAD" -> App(..acc, head: [new_route, ..acc.head])
      "OPTIONS" -> App(..acc, options: [new_route, ..acc.options])
      _ -> {
        let existing = dict.get(acc.custom, method) |> result.unwrap([])
        App(
          ..acc,
          custom: dict.insert(acc.custom, method, [new_route, ..existing]),
        )
      }
    }
  })
}

fn parse_path(path: String) -> List(String) {
  path
  |> string.split("/")
  |> list.filter(fn(s) { s != "" })
}

fn handle_request(app: App, req: Request(BitArray)) -> Response(BitArray) {
  let method = method_to_string(req.method)
  // Strip query string from path for matching
  let path = case string.split(req.path, "?") {
    [path, ..] -> path
    [] -> req.path
  }

  // Find matching route
  let routes = get_routes(app, method)
  case router.match_route(routes, path) {
    Ok(match) -> {
      // Build context with params
      let query_string = case req.query {
        Some(q) -> q
        None -> ""
      }
      let query_params = context.parse_query(query_string)
      let ctx =
        types.Context(req: req, params: match.params, query: query_params)

      // Run middleware chain then handler
      run_middleware(app.middleware, ctx, match.handler)
    }
    Error(_) ->
      app.not_found(types.Context(
        req: req,
        params: dict.new(),
        query: dict.new(),
      ))
  }
}

fn get_routes(app: App, method: String) -> List(Route) {
  case method {
    "GET" -> app.get
    "POST" -> app.post
    "PUT" -> app.put
    "DELETE" -> app.delete
    "PATCH" -> app.patch
    "HEAD" -> app.head
    "OPTIONS" -> app.options
    _ -> dict.get(app.custom, method) |> result.unwrap([])
  }
}

fn run_middleware(
  middlewares: List(Middleware),
  ctx: Context,
  handler: Handler,
) -> Response(BitArray) {
  case middlewares {
    [] -> handler(ctx)
    [mw, ..rest] -> {
      let next = fn(ctx) { run_middleware(rest, ctx, handler) }
      mw(ctx, next)
    }
  }
}

fn method_to_string(method) -> String {
  case method {
    Get -> "GET"
    Post -> "POST"
    Put -> "PUT"
    Delete -> "DELETE"
    Patch -> "PATCH"
    Head -> "HEAD"
    Options -> "OPTIONS"
    Trace -> "TRACE"
    Connect -> "CONNECT"
    Other(m) -> m
  }
}
