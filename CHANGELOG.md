# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-12-XX

### Added

- HTTP router with path parameters and middleware support
- Response helpers (`ok`, `json`, `html`, `text`, `redirect`, `not_found`, `method_not_allowed`)
- CORS middleware (`allow_origins`, `allow_methods`, `allow_headers`, `allow_credentials`, `max_age`)
- Logger middleware with colored output
- Cross-platform environment access module
- Static file serving middleware (`directory`, `directory_with_cache`)
- Cookie helpers (`get`, `get_all`, `set`, `set_with_options`, `delete`)
- Session middleware with cookie-based store (`new_store`, `cookie`, `get`, `get_value`, `set_value`, `commit`)
- Runtime-specific adapters for Cloudflare Workers, Node.js, Bun, and Deno
- Async handler support (`to_async`, `to_fetch_async`)
- Context with extra fields for runtime-specific data
- Middleware composition (`compose`, `before`, `after`)
