---
description: Scaffold a spatie/laravel-permission role or permission — add it to the seeder, ensure the HasRoles trait, and wire any requested middleware/policy checks. Use when the user mentions roles, permissions, spatie, HasRoles, @can, role/permission middleware, or "give X access to Y".
argument-hint: [the role/permission to add + where to enforce it]
---

You're the **/permission** skill. Turn the request into an enriched delegation to the `permission` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The **permission(s)** to add (stable dotted names — `invoices.view`, `orders.refund`) and/or the **role(s)** (`admin`, `billing-manager`).
- Where to **enforce** it, if stated — a route/controller (middleware), a policy/gate check, a Blade view (`@can`).

## Step 2: Resolve
- Which model is the authenticatable (the one that should carry `HasRoles`) — check the project; default to the app's user model.
- What roles/permissions already exist — read the names captured by the `permissions` concern in `.bench/` (the source of truth). Reuse real names; don't invent parallel ones.
- Ambiguous scope → ask which role gets the permission, or where it's enforced.

## Step 3: Build context blob
```
- Add permission(s): {names}   role(s): {names}   grant: {which perms → which roles}
- Authenticatable: {Model}  (ensure HasRoles)
- Enforce at: {route/controller middleware | policy/gate | Blade @can | none stated}
- Existing names (from .bench/): {list or "none captured"}
- Original request: {verbatim}
```

## Step 4: Delegate
Hand the blob to the `permission` agent (Task). It reads `PERMISSION-002-spatie`, updates the roles-and-permissions seeder, ensures `HasRoles`, and wires the requested checks. Surface its summary (files touched, names added, follow-ups like running the seeder / publishing migrations).

## Anti-Patterns
- ❌ Writing files yourself — delegate to the agent.
- ❌ Inventing permission names not in the project's captured set.
- ❌ Scaffolding raw role-string checks where a permission is the stable unit.

## Not covered by a pattern?

If the request needs a **spatie-permission** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "spatie-permission" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
