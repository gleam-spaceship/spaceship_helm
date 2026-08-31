// spaceship_helm FFI for JavaScript
// Handles conversion between Web Fetch API and gleam_http types

import { Request } from "./build/dev/javascript/spaceship_helm/spaceship_helm.mjs";

/**
 * Create a fetch handler from a spaceship_helm app
 * @param {Function} app_handler - The to_fetch() handler from spaceship_helm
 * @returns {Function} A fetch handler for JS runtimes
 */
export function create_fetch_handler(app_handler) {
  return async function handle(request) {
    try {
      // Convert Web Fetch Request to gleam_http Request
      const gleam_request = await convert_to_gleam_request(request);
      
      // Call the Gleam handler
      const response = app_handler(gleam_request);
      
      // Convert back to Web Fetch Response
      return convert_to_web_response(response);
    } catch (error) {
      console.error("spaceship_helm error:", error);
      return new Response("Internal Server Error", { status: 500 });
    }
  };
}

/**
 * Convert Web Fetch Request to gleam_http Request format
 */
async function convert_to_gleam_request(request) {
  const url = new URL(request.url);
  
  // Read body
  let body = new Uint8Array(0);
  if (request.body) {
    const chunks = [];
    const reader = request.body.getReader();
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      chunks.push(value);
    }
    const totalLength = chunks.reduce((acc, chunk) => acc + chunk.length, 0);
    body = new Uint8Array(totalLength);
    let offset = 0;
    for (const chunk of chunks) {
      body.set(chunk, offset);
      offset += chunk.length;
    }
  }
  
  // Convert headers to dict format (list of tuples in gleam)
  const headers = [];
  for (const [key, value] of request.headers.entries()) {
    headers.push([key, value]);
  }
  
  // Map method string to gleam_http method
  const method = map_method(request.method);
  
  // gleam_http Request format
  return {
    scheme: { scheme: "https", _null: null },
    host: url.hostname,
    port: url.port ? parseInt(url.port) : 443,
    path: url.pathname,
    query: url.search.substring(1) || "",
    method: method,
    headers: headers,
    body: body,
  };
}

/**
 * Convert gleam_http Response to Web Fetch Response
 */
function convert_to_web_response(gleam_response) {
  const status = gleam_response.status;
  const headers = new Headers();
  
  // gleam_http response has headers as list of tuples
  if (gleam_response.headers) {
    for (const [key, value] of gleam_response.headers) {
      headers.append(key, value);
    }
  }
  
  // Body is a BitArray (Uint8Array in JS)
  const body = gleam_response.body;
  
  return new Response(body, {
    status: status,
    headers: headers,
  });
}

/**
 * Map HTTP method string to gleam_http method type
 */
function map_method(method) {
  const methods = {
    'GET': { get: null },
    'POST': { post: null },
    'PUT': { put: null },
    'DELETE': { delete: null },
    'PATCH': { patch: null },
    'HEAD': { head: null },
    'OPTIONS': { options: null },
    'TRACE': { trace: null },
    'CONNECT': { connect: null },
  };
  return methods[method] || { custom: method };
}

/**
 * Parse query string to dict format
 */
export function parse_query(query_string) {
  if (!query_string) return [];
  
  const params = [];
  for (const pair of query_string.split('&')) {
    const [key, value] = pair.split('=');
    if (key) {
      params.push([
        decodeURIComponent(key),
        value ? decodeURIComponent(value) : ''
      ]);
    }
  }
  return params;
}

/**
 * Create a dict from array of key-value pairs
 */
export function dict_from_pairs(pairs) {
  const dict = new Map();
  for (const [key, value] of pairs) {
    dict.set(key, value);
  }
  return dict;
}
