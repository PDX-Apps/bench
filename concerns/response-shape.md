---
concern: response-shape
title: API response shape
order: 40
questions:
  - id: envelope
    ask: "What shape do API responses take?"
    options: [plain-resource, wrapped-envelope, custom]
    default: plain-resource
  - id: envelope_keys
    ask: "If wrapped, what's the shape? (e.g. { status, data } or { data, meta }) — skip for plain."
    default: "{ data }"
affects:
  - laravel/http/resources/RESOURCE-001-api-resources.md
  - laravel/http/responses/RESPONSE-001-standard.md
output: overrides
---

## Apply

Write `.bench/patterns/...` overrides (mode `append`):

- **RESOURCE-001-api-resources.md** — if `wrapped-envelope`/`custom`, the resource/response wraps payloads as `{envelope_keys}` (e.g. via a base resource or a response macro); if `plain-resource`, the default JsonResource shape is correct (no override needed — note it).
- **RESPONSE-001-standard.md** — the standard success/error response shape the project uses, so generated controllers return it consistently.
