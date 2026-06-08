# spatie-permission

spatie/laravel-permission conventions + scaffolding for Laravel: DB-backed roles and
permissions, the `HasRoles` trait on the authenticatable, checks via `can()` / `hasRole()`
(Blade `@can`, route middleware), and a super-admin `Gate::before`.

## What it ships

- **`/permission`** — a command + `permission` agent that scaffolds a role/permission: adds it
  to the roles-and-permissions seeder, ensures `HasRoles` on the user model, and wires any
  requested middleware/policy/Blade checks.
- **`PERMISSION-002-spatie`** — the pattern: the concrete spatie implementation of the
  authorization model that core's `PERMISSION-001-model` documents in the abstract.

## Install

```bash
bench addon add spatie-permission
```

## Pairs with the core `permissions` concern

Core stays package-agnostic: the `permissions` concern (run at `/bench-init`) detects
`spatie/laravel-permission` and captures **your project's actual role and permission names**
into `.bench/`. This addon supplies the **how** — the spatie idioms and scaffolding — and the
`/permission` agent uses the captured names as the source of truth, so generated authorization
references real permissions rather than invented ones.
