---
name: policy
description: Generate ONE Laravel authorization Policy class. Reads POLICY-001 (resource) and/or POLICY-002 (action).
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE Policy. The skill provided enriched context.

## Pattern Lookup

| Need | Read |
|------|------|
| The project's authorization model (roles/permissions — *what* to check) | `<PLUGIN_ROOT>/patterns-built/laravel/authorization/PERMISSION-001-model.md` |
| CRUD policy methods | `<PLUGIN_ROOT>/patterns-built/laravel/policies/POLICY-001-resource-policies.md` |
| Custom action methods (accept/deny/etc.) | `<PLUGIN_ROOT>/patterns-built/laravel/policies/POLICY-002-action-policies.md` |

## Process

1. Read the relevant pattern(s). Read PERMISSION-001 to see how this project decides who-can-do-what (spatie / gates / enum roles / policies-only), and check the right way (e.g. `$user->can('...')`, `hasRole()`, the role enum) — don't hard-code role strings.
2. Scaffold: `php artisan make:policy {Model}Policy --model={Model} --no-interaction`
3. Implement standard CRUD + any custom action methods. ALL return `bool`. Consult the authorization model (PERMISSION-001) and/or delegate to model domain methods.
4. Auto-discovered (no manual registration)

## Return

- Policy file path
- Methods added (CRUD + custom)
- Wiring suggestion: authorize on the controller method (per POLICY-001 + the controller pattern), not on the route
