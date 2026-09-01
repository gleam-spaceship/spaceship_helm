// Node.js adapter for spaceship_helm
// Converts between Node.js http.IncomingMessage/http.ServerResponse and Gleam request/response types

import { Some, None } from "../../dev/javascript/gleam_stdlib/gleam/option.mjs";
import { Get, Post, Put, Delete, Patch, Head, Options } from "../../dev/javascript/gleam_http/gleam/http.mjs";

class Http {}

function gleamList(arr) {
  let list = { head: undefined, tail: undefined };
  for (let i = arr.length - 1; i >= 0; i--) {
    list = { head: arr[i], tail: list };
  }
  return list;
}

export function toGleamRequest(req) {
  // req is http.IncomingMessage
  const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);
  const query = url.search ? url.search.substring(1) : null;

  const methodMap = {
    GET: new Get(),
    POST: new Post(),
    PUT: new Put(),
    DELETE: new Delete(),
    PATCH: new Patch(),
    HEAD: new Head(),
    OPTIONS: new Options(),
  };

  const method = methodMap[req.method] || new Get();

  const headers = [];
  for (const [key, value] of Object.entries(req.headers)) {
    if (value !== undefined) {
      headers.push([key, Array.isArray(value) ? value.join(", ") : value]);
    }
  }

  return {
    constructor: "Request",
    method,
    headers: gleamList(headers),
    body: new Uint8Array(0),
    scheme: new Http(),
    host: url.hostname,
    port: url.port ? parseInt(url.port) : null,
    path: url.pathname,
    query: query !== null ? new Some(query) : new None(),
  };
}

export function toPlatformResponse(resp, serverResponse) {
  // serverResponse is http.ServerResponse
  const headers = {};
  let h = resp.headers;
  while (h && h.head) {
    headers[h.head[0]] = h.head[1];
    h = h.tail;
  }

  serverResponse.writeHead(resp.status, headers);

  let body = resp.body;
  if (body) {
    if (body.buffer instanceof Uint8Array) {
      serverResponse.end(Buffer.from(body.buffer));
    } else if (body.data instanceof Uint8Array) {
      serverResponse.end(Buffer.from(body.data));
    } else if (body instanceof Uint8Array) {
      serverResponse.end(Buffer.from(body));
    } else {
      serverResponse.end();
    }
  } else {
    serverResponse.end();
  }
}
