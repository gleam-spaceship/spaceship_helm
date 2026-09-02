import filepath
import gleam/http
import gleam/http/response
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import simplifile
import spaceship_helm/types.{type Context, type Middleware}

/// MIME type mappings for common file extensions
fn mime_type(path: String) -> String {
  let ext = case string.split(path, ".") {
    [] -> ""
    parts -> {
      let last = list.last(parts) |> result.unwrap("")
      string.lowercase(last)
    }
  }
  case ext {
    "html" | "htm" -> "text/html; charset=utf-8"
    "css" -> "text/css; charset=utf-8"
    "js" | "mjs" -> "application/javascript; charset=utf-8"
    "json" -> "application/json; charset=utf-8"
    "png" -> "image/png"
    "jpg" | "jpeg" -> "image/jpeg"
    "gif" -> "image/gif"
    "svg" -> "image/svg+xml"
    "ico" -> "image/x-icon"
    "woff" -> "font/woff"
    "woff2" -> "font/woff2"
    "ttf" -> "font/ttf"
    "otf" -> "font/otf"
    "pdf" -> "application/pdf"
    "txt" -> "text/plain; charset=utf-8"
    "xml" -> "application/xml; charset=utf-8"
    "wasm" -> "application/wasm"
    "webp" -> "image/webp"
    "mp4" -> "video/mp4"
    "webm" -> "video/webm"
    "zip" -> "application/zip"
    _ -> "application/octet-stream"
  }
}

/// Create a static file serving middleware.
///
/// Serves files from the specified directory relative to the current working
/// directory. If a file is found, it returns the file content with the
/// appropriate Content-Type header. If not found, passes to the next handler.
///
/// # Usage
///
/// ```gleam
/// let app = lustre.fetch("/", handler)
/// |> lustre.use(static.directory("public"))
/// ```
pub fn directory(dir: String) -> Middleware {
  fn(ctx: Context, next) {
    case ctx.req.method {
      http.Get -> {
        let path = case ctx.req.path {
          "/" -> "/index.html"
          p -> p
        }
        let full_path = filepath.join(dir, string.drop_start(path, 1))
        do_read_file(full_path)
        |> fn(result) {
          case result {
            Ok(content) -> {
              let content_type = mime_type(path)
              response.new(200)
              |> response.set_header("content-type", content_type)
              |> response.set_header("cache-control", "public, max-age=3600")
              |> response.set_body(content)
            }
            Error(_) -> next(ctx)
          }
        }
      }
      _ -> next(ctx)
    }
  }
}

/// Create a static file serving middleware with custom cache duration.
///
/// # Usage
///
/// ```gleam
/// let app = lustre.fetch("/", handler)
/// |> lustre.use(static.directory_with_cache("public", 86400))
/// ```
pub fn directory_with_cache(dir: String, max_age: Int) -> Middleware {
  fn(ctx: Context, next) {
    case ctx.req.method {
      http.Get -> {
        let path = case ctx.req.path {
          "/" -> "/index.html"
          p -> p
        }
        let full_path = filepath.join(dir, string.drop_start(path, 1))
        do_read_file(full_path)
        |> fn(result) {
          case result {
            Ok(content) -> {
              let content_type = mime_type(path)
              let cache_header = "public, max-age=" <> int.to_string(max_age)
              response.new(200)
              |> response.set_header("content-type", content_type)
              |> response.set_header("cache-control", cache_header)
              |> response.set_body(content)
            }
            Error(_) -> next(ctx)
          }
        }
      }
      _ -> next(ctx)
    }
  }
}

/// Read a file from the filesystem.
/// Returns Ok(BitArray) with file content or Error(Nil) if not found.
fn do_read_file(path: String) -> Result(BitArray, Nil) {
  case simplifile.read_bits(path) {
    Ok(content) -> Ok(content)
    Error(_) -> Error(Nil)
  }
}
