// Session FFI for JavaScript

/**
 * Generate a random session ID (32 hex characters).
 * @returns {string} Random session ID
 */
export function generateSessionId() {
  const bytes = new Uint8Array(16);
  crypto.getRandomValues(bytes);
  return Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
}

/**
 * Create a new in-memory session store.
 * @returns {Map} Session store (Map<string, {id: string, data: Map<string, string>}>)
 */
export function createStore() {
  return new Map();
}

/**
 * Get a value from the session store.
 * @param {Map} store - Session store
 * @param {string} key - Session ID
 * @returns {Object|null} Session object or null if not found
 */
export function getStoreValue(store, key) {
  return store.get(key) || null;
}

/**
 * Set a value in the session store.
 * @param {Map} store - Session store
 * @param {string} key - Session ID
 * @param {Map} value - Session data (Map<string, string>)
 */
export function setStoreValue(store, key, value) {
  // Convert Gleam Dict to plain object for storage
  const data = {};
  if (value && typeof value === 'object') {
    // Gleam Dict is stored as a object with keys property
    if (value.keys && typeof value.keys === 'function') {
      for (const k of value.keys()) {
        data[k] = value.get(k);
      }
    } else {
      // Try to copy as plain object
      Object.assign(data, value);
    }
  }
  store.set(key, { id: key, data });
}

/**
 * Get session data as a Gleam Dict-compatible object.
 * @param {Map} store - Session store
 * @param {string} key - Session ID
 * @returns {Object} Session data as object with keys() method
 */
export function getSessionData(store, key) {
  const session = store.get(key);
  if (!session) {
    return createGleamDict({});
  }
  return createGleamDict(session.data);
}

/**
 * Create a Gleam-compatible Dict object from a plain object.
 * @param {Object} obj - Plain object
 * @returns {Object} Gleam Dict-compatible object
 */
function createGleamDict(obj) {
  const entries = Object.entries(obj);
  return {
    size: entries.length,
    entries: entries,
    keys() {
      return entries.map(([k]) => k);
    },
    get(key) {
      const entry = entries.find(([k]) => k === key);
      return entry ? entry[1] : undefined;
    },
    has(key) {
      return entries.some(([k]) => k === key);
    }
  };
}

/**
 * Check if a value is null or undefined.
 * @param {*} value - Value to check
 * @returns {boolean} True if null or undefined
 */
export function isNull(value) {
  return value === null || value === undefined;
}

/**
 * Convert a Session to a Dynamic value for storage.
 * @param {Object} session - Session object {id, data}
 * @returns {Object} Dynamic wrapper
 */
export function sessionToDynamic(session) {
  return { __tag: "Session", id: session.id, data: session.data };
}

/**
 * Convert a Dynamic value back to a Session.
 * @param {*} value - Dynamic value
 * @returns {Object} Session object
 */
export function dynamicToSession(value) {
  if (value && value.__tag === "Session") {
    return { id: value.id, data: value.data };
  }
  // Fallback for plain objects
  if (value && typeof value === "object" && "id" in value && "data" in value) {
    return { id: value.id, data: value.data };
  }
  return { id: "", data: {} };
}
