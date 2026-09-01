// Deno adapter for spaceship_helm
// Converts between Fetch API and Gleam request/response types

import { Some, None } from "../../dev/javascript/gleam_stdlib/gleam/option.mjs";
import { Get, Post, Put, Delete, Patch, Head, Options } from "../../dev/javascript/gleam_http/gleam/http.mjs";

class Http {}
class Https {}

function gleamList(arr) {
  let list = { head: undefined, tail: undefined };
  for (let i = arr.length - 1; i >= 0; i--) {
    list = { head: arr[i], tail: list };
  }
  return list;
}

export function toGleamRequest(req) {
  const url = new URL(req.url);
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
  req.headers.forEach((v, k) => headers.push([k, v]));

  return {
    constructor: "Request",
    method,
    headers: gleamList(headers),
    body: new Uint8Array(0),
    scheme: url.protocol === "https:" ? new Https() : new Http(),
    host: url.hostname,
    port: url.port ? parseInt(url.port) : null,
    path: url.pathname,
    query: query !== null ? new Some(query) : new None(),
  };
}

export function toPlatformResponse(resp) {
  const headers = new Headers();
  let h = resp.headers;
  while (h && h.head) {
    headers.set(h.head[0], h.head[1]);
    h = h.tail;
  }

  let body = resp.body;
  if (body) {
    if (body.buffer instanceof Uint8Array) {
      body = body.buffer;
    } else if (body.data instanceof Uint8Array) {
      body = body.data;
    }
  }

  return new Response(body, { status: resp.status, headers });
}
