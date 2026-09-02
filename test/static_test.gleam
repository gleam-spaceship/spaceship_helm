import gleeunit
import spaceship_helm/static

pub fn main() -> Nil {
  gleeunit.main()
}

pub fn static_directory_returns_middleware_test() {
  // Verify that directory() returns a middleware function without errors
  let _mw = static.directory("public")
  Nil
}

pub fn static_directory_with_cache_returns_middleware_test() {
  // Verify that directory_with_cache() returns a middleware function
  let _mw = static.directory_with_cache("public", 86400)
  Nil
}
