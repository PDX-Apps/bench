---
mode: append
---

## Octane safety (this project uses laravel-octane)

The worker boots once under Octane, so bindings registered here outlive a single request.
Use `scoped` (flushed and re-resolved per request) instead of `singleton` for anything that
holds request state, the current user, or `Request`/`auth`/`session`. A `singleton` that
captures `Request` at construction freezes on the first request and returns stale data
forever; an unbounded `static`/property cache becomes a slow memory leak.
