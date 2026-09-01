import gleam/dict.{type Dict}
import gleam/list
import gleam/string
import spaceship_helm/types.{
  type AsyncHandler, type AsyncRoute, type Handler, type Route,
}

pub type Match {
  Match(handler: Handler, params: Dict(String, String))
}

pub type AsyncMatch {
  AsyncMatch(handler: AsyncHandler, params: Dict(String, String))
}

pub fn match_route(routes: List(Route), path: String) -> Result(Match, Nil) {
  let segments = split_path(path)
  routes
  |> list.find_map(fn(route) { try_match(route, segments) })
}

pub fn match_async_route(
  routes: List(AsyncRoute),
  path: String,
) -> Result(AsyncMatch, Nil) {
  let segments = split_path(path)
  routes
  |> list.find_map(fn(route) { try_match_async(route, segments) })
}

fn try_match_async(
  route: AsyncRoute,
  segments: List(String),
) -> Result(AsyncMatch, Nil) {
  case match_segments(route.path, segments, dict.new()) {
    Ok(params) -> Ok(AsyncMatch(handler: route.handler, params: params))
    Error(Nil) -> Error(Nil)
  }
}

fn try_match(route: Route, segments: List(String)) -> Result(Match, Nil) {
  case match_segments(route.path, segments, dict.new()) {
    Ok(params) -> Ok(Match(handler: route.handler, params: params))
    Error(Nil) -> Error(Nil)
  }
}

fn match_segments(
  pattern: List(String),
  segments: List(String),
  params: Dict(String, String),
) -> Result(Dict(String, String), Nil) {
  case pattern, segments {
    // Wildcard pattern — matches everything remaining
    ["*name"], rest -> {
      let value = rest |> list.intersperse("/") |> string.concat
      let params = dict.insert(params, "name", value)
      let params = dict.insert(params, "*name", value)
      Ok(params)
    }

    // Both empty — match
    [], [] -> Ok(params)

    // Pattern has more segments
    [_, ..], [] -> Error(Nil)

    // Segments has more but pattern is empty
    [], [_, ..] -> Error(Nil)

    // Both have segments
    [p, ..rest_p], [s, ..rest_s] -> {
      case is_param(p) {
        True -> {
          let name = extract_param_name(p)
          let params = dict.insert(params, name, s)
          match_segments(rest_p, rest_s, params)
        }
        False -> {
          case p == s {
            True -> match_segments(rest_p, rest_s, params)
            False -> Error(Nil)
          }
        }
      }
    }
  }
}

fn is_param(segment: String) -> Bool {
  string.starts_with(segment, ":")
}

fn extract_param_name(segment: String) -> String {
  case string.starts_with(segment, ":") {
    True -> string.drop_start(segment, 1)
    False -> segment
  }
}

fn split_path(path: String) -> List(String) {
  path
  |> string.split("/")
  |> list.filter(fn(s) { s != "" })
}
