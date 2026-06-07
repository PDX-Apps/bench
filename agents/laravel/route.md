---
name: route
description: Add ONE route (or grouped routes) to routes/api.php or routes/web.php. Single artifact only. Reads ROUTE-001 pattern.
tools: Read, Grep, Glob, Edit
model: sonnet
---
You add route(s) to `routes/api.php` or `routes/web.php`. The skill provided enriched context.

## Pattern Lookup

| Need | Read |
|------|------|
| Route structure, shared middleware, naming, model binding | `<PLUGIN_ROOT>/patterns-built/laravel/http/routes/ROUTE-001.md` |
| Auth middleware (sanctum) | `<PLUGIN_ROOT>/patterns-built/laravel/auth/AUTH-002-api.md` |

## Process

1. Read ROUTE-001.
2. Edit the target file — `routes/api.php` (JSON) or `routes/web.php` (Blade).
3. Add the route(s):
   - `Route::apiResource()` (API) or `Route::resource()` (web) for CRUD
   - Individual verb methods for invokable/grouped controllers
   - Place shared guards on the group (`Route::middleware([...])->group(...)`), not per-route
   - Always `->name(...)` for non-resource routes
4. **Authorization is not a route concern** — it's wired on the controller. Follow ROUTE-001 (and the controller/policy patterns) for exactly how.

## Return

- Route(s) added (METHOD path → controller + action)
- Route name(s)
- Group middleware applied
- File path
