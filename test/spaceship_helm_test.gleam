import gleam/http.{Get, Post, Put}
import gleam/http/request
import gleam/http/response
import gleam/list
import gleam/option
import gleeunit
import gleeunit/should
import spaceship_helm
import spaceship_helm/context

pub fn main() {
  gleeunit.main()
}

// Test basic routing
pub fn test_basic_get_route_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/", fn(_ctx) {
      response.new(200)
      |> response.set_body(<<"Hello, World!":utf8>>)
    })

  let req =
    request.new()
    |> request.set_path("/")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let handler = spaceship_helm.to_fetch(app)
  let resp = handler(req)

  resp.status
  |> should.equal(200)
}

// Test path parameters
pub fn test_path_params_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/users/:id", fn(ctx) {
      let id = context.param(ctx, "id")
      response.new(200)
      |> response.set_body(<<id:utf8>>)
    })

  let req =
    request.new()
    |> request.set_path("/users/123")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let handler = spaceship_helm.to_fetch(app)
  let resp = handler(req)

  resp.status
  |> should.equal(200)

  resp.body
  |> should.equal(<<"123":utf8>>)
}

// Test query parameters
pub fn test_query_params_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/search", fn(ctx) {
      let query = context.query(ctx, "q") |> option.unwrap("")
      response.new(200)
      |> response.set_body(<<query:utf8>>)
    })

  let req =
    request.new()
    |> request.set_path("/search")
    |> request.set_query([#("q", "hello")])
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let handler = spaceship_helm.to_fetch(app)
  let resp = handler(req)

  resp.status
  |> should.equal(200)

  resp.body
  |> should.equal(<<"hello":utf8>>)
}

// Test multiple HTTP methods
pub fn test_http_methods_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/resource", fn(_ctx) {
      response.new(200) |> response.set_body(<<"GET":utf8>>)
    })
    |> spaceship_helm.post("/resource", fn(_ctx) {
      response.new(201) |> response.set_body(<<"POST":utf8>>)
    })
    |> spaceship_helm.put("/resource", fn(_ctx) {
      response.new(200) |> response.set_body(<<"PUT":utf8>>)
    })

  let handler = spaceship_helm.to_fetch(app)

  // Test GET
  let get_req =
    request.new()
    |> request.set_path("/resource")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let get_resp = handler(get_req)
  get_resp.status |> should.equal(200)
  get_resp.body |> should.equal(<<"GET":utf8>>)

  // Test POST
  let post_req =
    request.new()
    |> request.set_path("/resource")
    |> request.set_method(Post)
    |> request.set_body(<<>>)

  let post_resp = handler(post_req)
  post_resp.status |> should.equal(201)
  post_resp.body |> should.equal(<<"POST":utf8>>)

  // Test PUT
  let put_req =
    request.new()
    |> request.set_path("/resource")
    |> request.set_method(Put)
    |> request.set_body(<<>>)

  let put_resp = handler(put_req)
  put_resp.status |> should.equal(200)
  put_resp.body |> should.equal(<<"PUT":utf8>>)
}

// Test middleware
pub fn test_middleware_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.middleware(fn(ctx, next) {
      let resp = next(ctx)
      response.set_header(resp, "x-custom", "value")
    })
    |> spaceship_helm.get("/", fn(_ctx) {
      response.new(200) |> response.set_body(<<"OK":utf8>>)
    })

  let req =
    request.new()
    |> request.set_path("/")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let handler = spaceship_helm.to_fetch(app)
  let resp = handler(req)

  resp.status
  |> should.equal(200)

  // Check custom header exists
  // Headers are stored as a list of tuples
  resp.headers
  |> list.find(fn(h) {
    let #(key, _) = h
    key == "x-custom"
  })
  |> should.be_ok
  |> fn(h) {
    let #(_, value) = h
    value
  }
  |> should.equal("value")
}

// Test not found handler
pub fn test_not_found_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/", fn(_ctx) {
      response.new(200) |> response.set_body(<<"OK":utf8>>)
    })
    |> spaceship_helm.not_found(fn(_ctx) {
      response.new(404) |> response.set_body(<<"Custom 404":utf8>>)
    })

  let req =
    request.new()
    |> request.set_path("/nonexistent")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let handler = spaceship_helm.to_fetch(app)
  let resp = handler(req)

  resp.status
  |> should.equal(404)

  resp.body
  |> should.equal(<<"Custom 404":utf8>>)
}

// Test route grouping
pub fn test_route_grouping_test() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.group("/api/v1", fn(app) {
      app
      |> spaceship_helm.get("/users", fn(_ctx) {
        response.new(200) |> response.set_body(<<"Users":utf8>>)
      })
      |> spaceship_helm.get("/posts", fn(_ctx) {
        response.new(200) |> response.set_body(<<"Posts":utf8>>)
      })
    })

  let handler = spaceship_helm.to_fetch(app)

  // Test /api/v1/users
  let users_req =
    request.new()
    |> request.set_path("/api/v1/users")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let users_resp = handler(users_req)
  users_resp.status |> should.equal(200)
  users_resp.body |> should.equal(<<"Users":utf8>>)

  // Test /api/v1/posts
  let posts_req =
    request.new()
    |> request.set_path("/api/v1/posts")
    |> request.set_method(Get)
    |> request.set_body(<<>>)

  let posts_resp = handler(posts_req)
  posts_resp.status |> should.equal(200)
  posts_resp.body |> should.equal(<<"Posts":utf8>>)
}
