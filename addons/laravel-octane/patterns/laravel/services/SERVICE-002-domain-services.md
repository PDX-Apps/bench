---
mode: append
---

## Octane safety (this project uses laravel-octane)

Under Octane the worker is long-lived, so a service that stores per-request state (the
current `Request`, `auth`/`session` data, the current user) or grows a `static`/instance
cache will leak that state — or memory — across requests. Don't capture `Request` at
construction; inject it per method or use `request()`. Bind stateful services as `scoped`
(not `singleton`) so they're re-resolved per request.
