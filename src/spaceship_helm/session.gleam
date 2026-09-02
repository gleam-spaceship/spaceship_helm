/// Session management with cookie-based sessions.
///
/// This module provides session middleware that stores session data in
/// server-side memory and uses signed cookies for session identification.
///
/// # Usage
///
/// ```gleam
/// // Setup middleware with a store
/// let store = sessions.new_store()
/// let app = lustre.fetch("/", handler)
/// |> lustre.use(sessions.cookie("session_id", "my-secret-key", store))
///
/// // In handler - read session
/// use session <- sessions.get(ctx)
/// let username = sessions.get_value(session, "username")
///
/// // In handler - write session
/// let session = sessions.set_value(session, "username", "alice")
/// sessions.commit(response, session, store)
/// ```
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/result
import spaceship_helm/cookie
import spaceship_helm/types.{type Context, type Middleware}

/// A session with an ID and data store.
pub type Session {
  Session(id: String, data: Dict(String, String))
}

/// Session storage backend.
pub type SessionStore {
  SessionStore(data: Dynamic)
}

/// Create a new in-memory session store.
pub fn new_store() -> SessionStore {
  SessionStore(data: do_create_store())
}

/// Create a cookie-based session middleware.
///
/// This middleware:
/// 1. Reads the session ID from the cookie
/// 2. Loads the session data from the store
/// 3. Makes the session available via `sessions.get(ctx)`
/// 4. Saves the session data when the response is sent
///
/// # Arguments
///
/// * `cookie_name` - Name of the session cookie (e.g., "session_id")
/// * `_secret` - Secret key for signing the session ID (reserved for future use)
/// * `store` - Session storage backend
pub fn cookie(
  cookie_name: String,
  _secret: String,
  store: SessionStore,
) -> Middleware {
  fn(ctx: Context, next) {
    // Get session ID from cookie
    let session_id = case cookie.get(ctx.req, cookie_name) {
      Some(id) -> id
      None -> generate_session_id()
    }

    // Load or create session
    let session = load_or_create_session(session_id, store)

    // Store session in context for handlers to access
    let ctx =
      types.Context(
        ..ctx,
        extra: dict.insert(ctx.extra, "_session", session_to_dynamic(session)),
      )

    // Run the handler
    let resp = next(ctx)

    // Save session and set cookie
    save_session(session, store)
    resp
    |> cookie.set(cookie_name, session.id, 86_400)
  }
}

/// Get the session from the context.
///
/// This function is used with `use` syntax in handlers:
///
/// ```gleam
/// use session <- sessions.get(ctx)
/// let username = sessions.get_value(session, "username")
/// ```
pub fn get(ctx: Context, f: fn(Session) -> a) -> a {
  case dict.get(ctx.extra, "_session") {
    Ok(session_dynamic) -> {
      let session = dynamic_to_session(session_dynamic)
      f(session)
    }
    Error(_) -> {
      // No session middleware configured, return empty session
      f(Session(id: "", data: dict.new()))
    }
  }
}

/// Get a value from the session.
pub fn get_value(session: Session, key: String) -> Option(String) {
  dict.get(session.data, key)
  |> result.map(Some)
  |> result.unwrap(None)
}

/// Set a value in the session.
///
/// Returns a new session with the updated value.
pub fn set_value(session: Session, key: String, value: String) -> Session {
  Session(..session, data: dict.insert(session.data, key, value))
}

/// Save session and return the response.
///
/// This is a convenience function for saving session values:
///
/// ```gleam
/// let session = sessions.set_value(session, "username", "alice")
/// sessions.commit(response, session, store)
/// ```
pub fn commit(
  resp: Response(body),
  session: Session,
  store: SessionStore,
) -> Response(body) {
  save_session(session, store)
  resp
}

// ── Internal ──────────────────────────────────────────────────

/// Generate a random session ID.
fn generate_session_id() -> String {
  do_generate_session_id()
}

/// Load a session from the store or create a new one.
fn load_or_create_session(id: String, store: SessionStore) -> Session {
  case get_session_from_store(id, store) {
    Some(session) -> session
    None -> Session(id: id, data: dict.new())
  }
}

/// Get a session from the store.
fn get_session_from_store(id: String, store: SessionStore) -> Option(Session) {
  let value = do_get_store_value(store.data, id)
  // Check if value is null/undefined (not found)
  case is_null(value) {
    True -> None
    False -> {
      // Decode the stored session data
      let data = do_get_session_data(store.data, id)
      Some(Session(id: id, data: data))
    }
  }
}

/// Save a session to the store.
fn save_session(session: Session, store: SessionStore) -> Nil {
  do_set_store_value(store.data, session.id, session.data)
}

/// Convert Session to Dynamic for storage in context.
fn session_to_dynamic(session: Session) -> Dynamic {
  do_session_to_dynamic(session)
}

/// Convert Dynamic back to Session.
fn dynamic_to_session(value: Dynamic) -> Session {
  do_dynamic_to_session(value)
}

// ── FFI ───────────────────────────────────────────────────────

@external(javascript, "./ffi/session.mjs", "createStore")
fn do_create_store() -> Dynamic

@external(javascript, "./ffi/session.mjs", "getStoreValue")
fn do_get_store_value(store: Dynamic, key: String) -> Dynamic

@external(javascript, "./ffi/session.mjs", "setStoreValue")
fn do_set_store_value(
  store: Dynamic,
  key: String,
  value: Dict(String, String),
) -> Nil

@external(javascript, "./ffi/session.mjs", "getSessionData")
fn do_get_session_data(store: Dynamic, key: String) -> Dict(String, String)

@external(javascript, "./ffi/session.mjs", "generateSessionId")
fn do_generate_session_id() -> String

@external(javascript, "./ffi/session.mjs", "isNull")
fn is_null(value: Dynamic) -> Bool

@external(javascript, "./ffi/session.mjs", "sessionToDynamic")
fn do_session_to_dynamic(session: Session) -> Dynamic

@external(javascript, "./ffi/session.mjs", "dynamicToSession")
fn do_dynamic_to_session(value: Dynamic) -> Session
