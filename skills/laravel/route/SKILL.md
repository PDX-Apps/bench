---
description: Add a Laravel route to routes/api.php or routes/web.php. Use when the user wants ONLY route registration. For a complete HTTP feature (controller+request+resource+route), use /laravel instead.
argument-hint: [what the user needs]
---

You're the **/route** skill. Translate the user's route request into an enriched delegation to the `route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **File**: `api.php` (JSON) or `web.php` (Blade) — pick by what the controller returns
- **Method**: GET | POST | PUT | PATCH | DELETE | apiResource | resource
- **Path** (`/orders`, `/orders/{order}/mark-paid`)
- **Controller binding**: `[OrderController::class, 'index']` or `MarkOrderPaidController::class` (invokable)
- **Route name** (`orders.mark-paid`)
- **Shared middleware** for the group (e.g. `auth:sanctum`, `throttle`)

## Step 2: Resolve Ambiguity

- Controller missing → flag: "Route binds to `MarkOrderPaidController` — doesn't exist. Generate `/controller` first?"
- api.php vs web.php → JSON-returning controller → `api.php`; Blade view controller → `web.php`
- **Authorization is NOT a route concern** — it lives on the controller (`#[Authorize]`). Don't add `->can()`.
- Group middleware → if the route joins an existing guarded group, place it inside; otherwise note the guard the user wants

## Step 3: Build Context Blob

```
Context for route agent:
- File: routes/api.php | routes/web.php
- Method: POST | apiResource | etc.
- Path: /orders/{order}/mark-paid
- Controller: MarkOrderPaidController (invokable) | [OrderController::class, 'index']
- Route name: orders.mark-paid
- Group middleware: [auth:sanctum] (or "join existing group")
```

## Step 4: Delegate

Task tool, `subagent_type: "route"`, pass the blob.

## Step 5: Synthesize

Report the route added (METHOD path → controller), its name, and which group/middleware it sits under. Note authorization is on the controller action, not the route.

## When to Ask vs Assume

- File choice → by controller return type (JSON → api.php, view → web.php)
- Shared guards → on the route group (never per-route `->can()`)
- Resource routes → auto-named; non-resource routes → always `->name(...)`
