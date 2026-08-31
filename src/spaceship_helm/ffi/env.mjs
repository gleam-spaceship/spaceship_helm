import { Option$Some, Option$None } from "../../gleam.mjs";

// Detect the current runtime
function getRuntime() {
  if (typeof globalThis.Cloudflare !== 'undefined') return 'cloudflare';
  if (typeof Deno !== 'undefined') return 'deno';
  if (typeof Bun !== 'undefined') return 'bun';
  if (typeof process !== 'undefined' && process.versions?.node) return 'node';
  return 'unknown';
}

// Get environment variables from the platform
function getEnvStore(vars) {
  const runtime = getRuntime();
  
  // If vars is provided (from Cloudflare env), use it
  if (vars && typeof vars === 'object') {
    return vars;
  }
  
  // Otherwise, use platform-specific environment
  switch (runtime) {
    case 'node':
    case 'bun':
      return process.env;
    case 'deno':
      return Deno.env.toObject();
    case 'cloudflare':
      // Cloudflare env should be passed via init()
      console.warn('Cloudflare env not initialized. Use spaceship_helm/env.init(env) in your shim.');
      return {};
    default:
      return {};
  }
}

// Store for environment variables
let envStore = null;
let globalEnv = null;

function ensureEnvStore(vars) {
  if (envStore === null) {
    envStore = getEnvStore(vars);
  }
  return envStore;
}

export function init_env(vars) {
  envStore = getEnvStore(vars);
}

export function get_global_env() {
  if (globalEnv === null) {
    return { tag: 'None' };
  }
  return { tag: 'Some', 0: globalEnv };
}

export function set_global_env(env) {
  globalEnv = env;
  // Also initialize the env store if not already done
  if (envStore === null && env && env.vars) {
    envStore = getEnvStore(env.vars);
  }
}

export function get_env(vars, name) {
  const store = ensureEnvStore(vars);
  const value = store[name];
  if (value !== undefined && value !== null) {
    return new Option$Some(String(value));
  }
  return new Option$None();
}

export function get_all_env(vars) {
  const store = ensureEnvStore(vars);
  const result = [];
  for (const [key, value] of Object.entries(store)) {
    if (value !== undefined && value !== null) {
      result.push([key, String(value)]);
    }
  }
  return result;
}
