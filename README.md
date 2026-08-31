# spaceship_helm

A Hono-like HTTP router for Gleam, targeting JS fetch-based runtimes.

## Installation

```sh
gleam add spaceship_helm
```

## Quick Start

```gleam
import spaceship_helm
import spaceship_helm/context
import spaceship_helm/response

pub fn main() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/", fn(_ctx) {
      response.text("Hello, World!")
    })

  // Export for JS runtimes
  app |> spaceship_helm.to_fetch()
}
```

## Features

| Feature | Description |
|---------|-------------|
| HTTP Methods | `get`, `post`, `put`, `delete`, `patch`, `head`, `options`, `on` |
| Path Params | `:name` syntax for dynamic segments |
| Wildcards | `*name` to match remaining path |
| Query Params | Extract query string values |
| Middleware | Functional pipe composition |
| Route Groups | Namespace routes with prefixes |
| Response Helpers | `text`, `json`, `html`, `redirect` |
| Built-in Middleware | CORS, logger |
| Environment Variables | Cross-platform env access (Node, Cloudflare, Deno, Bun) |

## API

### Creating an App

```gleam
let app = spaceship_helm.new()
```

### Registering Routes

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.get("/", home_handler)
  |> spaceship_helm.post("/users", create_user)
  |> spaceship_helm.put("/users/:id", update_user)
  |> spaceship_helm.delete("/users/:id", delete_user)
  |> spaceship_helm.patch("/users/:id", patch_user)
  |> spaceship_helm.on("CUSTOM", "/custom", custom_handler)
```

### Path Parameters

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.get("/users/:id", fn(ctx) {
    let id = context.param(ctx, "id")
    response.text(id)
  })
```

### Query Parameters

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.get("/search", fn(ctx) {
    let query = context.query(ctx, "q") |> option.unwrap("")
    response.text(query)
  })
```

### Route Groups

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.group("/api/v1", fn(app) {
    app
    |> spaceship_helm.get("/users", list_users)
    |> spaceship_helm.get("/users/:id", get_user)
    |> spaceship_helm.post("/users", create_user)
  })
```

### Middleware

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.middleware(fn(ctx, next) {
    let resp = next(ctx)
    response.set_header(resp, "x-powered-by", "spaceship_helm")
  })
  |> spaceship_helm.get("/", home_handler)
```

### Built-in Middleware

```gleam
import spaceship_helm/middleware

let app =
  spaceship_helm.new()
  |> spaceship_helm.middleware(middleware.cors())
  |> spaceship_helm.middleware(middleware.logger(io.println))
```

### Response Helpers

```gleam
// Text
response.text("Hello")

// HTML
response.html("<h1>Hello</h1>")

// JSON
import gleam/json
response.json(json.object([#("name", json.string("Alice"))]))

// Redirect
response.redirect("/login")
response.redirect_permanent("/new-url")

// Status codes
response.bad_request("Invalid input")
response.unauthorized()
response.forbidden()
response.not_found()
response.internal_server_error()
response.no_content()
```

### Custom Not Found Handler

```gleam
let app =
  spaceship_helm.new()
  |> spaceship_helm.get("/", home_handler)
  |> spaceship_helm.not_found(fn(_ctx) {
    response.new(404) |> response.set_body(<<"Custom 404":utf8>>)
  })
```

## JavaScript Usage

```gleam
// app.gleam
import spaceship_helm

pub fn main() {
  let app =
    spaceship_helm.new()
    |> spaceship_helm.get("/", fn(_ctx) {
      spaceship_helm/response.text("Hello from Gleam!")
    })

  app |> spaceship_helm.to_fetch()
}
```

```js
// app.mjs
import handler from "./build/dev/javascript/app.mjs"

// Bun
export default { fetch: handler }

// Cloudflare Workers
export default { fetch: handler }

// Deno
Deno.serve(handler)

// Node.js (18+)
import { createServer } from "node:http"

const server = createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host}`)
  const request = new Request(url, { method: req.method, headers: req.headers })
  const response = await handler(request)
  res.writeHead(response.status, Object.fromEntries(response.headers))
  res.end(await response.arrayBuffer())
})

server.listen(3000)
```

## Environment Variables

Access environment variables across different runtimes:

```gleam
import spaceship_helm/env

// Get a single variable
let value = env.get("MY_VAR")  // Returns Option(String)

// Get with default
let value = env.get_or("MY_VAR", "default")

// Get required (panics if not set)
let value = env.get_required("DATABASE_URL")

// Check if exists
let exists = env.has("MY_VAR")

// Get all variables
let vars = env.all()  // List(#(String, String))
```

The env module works on:
- **Node.js**: `process.env`
- **Cloudflare Workers**: `env` parameter from fetch handler
- **Deno**: `Deno.env`
- **Bun**: `process.env`
- **Erlang**: `os:env()`

For Cloudflare Workers, initialize the env in your entry point:

```gleam
import spaceship_helm/env as helm_env

pub fn main(req, cf_env, ctx) {
  // Initialize env access with Cloudflare's env object
  helm_env.init(cf_env)
  
  // Now you can read variables
  let db_url = helm_env.get("DATABASE_URL")
  
  // Handle request
}
```

## License

Apache-2.0
