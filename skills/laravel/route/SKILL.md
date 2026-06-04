---
description: Add a Laravel route to a module's api.php (or web.php). Use when the user wants ONLY route registration. For a complete HTTP feature (controller+request+resource+route), use /api instead.
argument-hint: [what the user needs]
---

You're the **/route** skill. Translate the user's route request into an enriched delegation to the `route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Method**: GET | POST | PUT | PATCH | DELETE | apiResource (all 5)
- **Path** (`/bills`, `/bills/{bill}/members/{member}`)
- **Controller binding**: `[BillController::class, 'index']` or `MarkBillPaidController::class` (invokable)
- **Authorization**: `->can('markPaid', 'bill')` if non-CRUD action
- **Route name** (`bills.markPaid`, etc.)
- **Middleware** (sanctum is default for api.php)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/routes/ 2>/dev/null
ls Modules/{Module}/app/Http/Controllers/ 2>/dev/null  # confirm controller exists
cat Modules/{Module}/routes/api.php 2>/dev/null | head -30
```

## Step 3: Resolve Ambiguity

- Controller missing → flag: "Route binds to `MarkBillPaidController` — doesn't exist. Generate `/controller` first?"
- api.php vs web.php → assume `routes/api.php` for any module endpoint (project default)
- Authorization → if invokable/grouped action, use `->can()` (HTTP-006)
- Model binding → use `{bill}` for ULID-based binding (matches model's `getRouteKeyName()`)

## Step 4: Build Context Blob

```
Context for route agent:
- Module: {Module}
- File: Modules/{Module}/routes/api.php
- Method: POST | apiResource | etc.
- Path: /bills/{bill}/mark-paid
- Controller: MarkBillPaidController (invokable) | [BillController::class, 'index']
- Route name: bills.markPaid
- Authorization: ->can('markPaid', 'bill')
- Middleware: defaults (sanctum)
- Existing routes in file: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:route"`, pass the blob.

## Step 6: Synthesize

> "Added route `POST /bills/{bill}/mark-paid` → `MarkBillPaidController` to `Modules/Bill/routes/api.php`. Authorized via `->can('markPaid', 'bill')`. Named `bills.markPaid`."

## When to Ask vs Assume

- api.php for module routes → always (project rule, never web.php for module APIs)
- Sanctum middleware → default (handles both session + token)
- ULID binding → assume `{bill}` resolves via `public_id`
- `->can()` on routes → preferred over controller-side authorization for non-CRUD
