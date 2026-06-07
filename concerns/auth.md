---
concern: auth
title: Authentication
order: 20
detect: grep -qE "laravel/(fortify|breeze|passport|sanctum)" composer.json 2>/dev/null && grep -oE "laravel/(fortify|breeze|passport|sanctum)" composer.json | head -1 || echo sessions
questions:
  - id: strategy
    ask: "How does this project authenticate users?"
    options: [sanctum, fortify, breeze, passport, sessions, custom]
    default: detect
  - id: surface
    ask: "Which surface(s) need auth?"
    options: [api, web, both]
    default: both
  - id: wrapper
    ask: "Is there a custom auth service/wrapper around Laravel's auth (e.g. an AuthService class)? If so, name it."
    default: none
affects:
  - laravel/auth/AUTH-001-web.md
  - laravel/auth/AUTH-002-api.md
output: overrides
---

## Apply

Write `.bench/patterns/...` overrides (mode `append`) to the auth pattern(s) relevant to `{surface}`:

- **AUTH-002-api.md** (if surface is api/both) — the API auth mechanism for `{strategy}` (e.g. Sanctum tokens/SPA, Passport OAuth, Fortify headless). How agents should guard API routes and resolve the current user.
- **AUTH-001-web.md** (if surface is web/both) — the web/session auth for `{strategy}` (Breeze/Fortify scaffolding, session guard).
- If `{wrapper}` is not `none` — append to both: "this project wraps auth in `{wrapper}`; resolve the current user / checks through it, not Laravel's `auth()` directly." Cite where it lives if discoverable.

Keep it to what the project actually uses; don't document every strategy.
