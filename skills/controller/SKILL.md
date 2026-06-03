---
description: Generate a single Laravel controller — resource (CRUD), invokable (single action), or grouped (related non-CRUD actions). Use whenever the user wants ONLY a controller (not the full HTTP stack). For full HTTP layer (controller+request+resource+route), use /api instead.
argument-hint: [what the user needs]
---

You're the **/controller** skill. Translate the user's controller request into an enriched delegation to the `controller` agent. Generates ONE controller; for full HTTP stacks use `/api`.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Controller class name** (e.g., `BillController`, `MarkBillPaidController`, `InvitationResponseController`)
- **Type** — one of:
  - `crud` — standard 5-method resource controller (HTTP-001)
  - `invokable` — single `__invoke()` action (HTTP-005)
  - `grouped` — 2-5 related non-CRUD actions on a resource (HTTP-006)
- **Resource** — the model the controller acts on (Bill, Invitation)

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Http/Controllers/ 2>/dev/null
ls Modules/{Module}/app/Models/ 2>/dev/null   # confirm resource exists
ls Modules/{Module}/app/Policies/ 2>/dev/null # for authorizeResource()
```

## Step 3: Resolve Ambiguity

- Type unclear → ask: "Resource CRUD (5 methods), invokable (1 action), or grouped (2-5 related actions)?"
- Resource missing → flag: "Controller for `Bill` — model doesn't exist. Generate `/model` first?"
- Standard CRUD → `authorizeResource(Bill::class)` in constructor (assume yes)
- Invokable/grouped → authorization via `->can()` on routes (not in controller)

## Step 4: Build Context Blob

```
Context for controller agent:
- Module: {Module}
- Class: {Name}Controller
- Type: crud | invokable | grouped
- Path: Modules/{Module}/app/Http/Controllers/{Name}Controller.php
- Resource: {Model}
- Authorization: authorizeResource({Model}::class) | route ->can() | none
- Policy exists: yes/no (path)
- Existing siblings: [BillController.php, MarkBillPaidController.php]
- Naming pattern observed: e.g., invokables prefixed with verb
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:controller"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Http/Controllers/MarkBillPaidController.php` (invokable, single `__invoke()`). Authorization via `->can('markPaid', 'bill')` in route. No FormRequest generated — invoke `/request` if you need one."

## When to Ask vs Assume

- 404/403/422/401 responses → handled by Laravel automatically; controller doesn't return them
- Resource controller → exactly 5 methods, no extras (per HTTP-001)
- Invokable naming → `{Verb}{Noun}Controller`
- `authorizeResource()` for CRUD → assume yes if policy exists
