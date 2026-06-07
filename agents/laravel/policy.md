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
| CRUD policy methods | `<PLUGIN_ROOT>/patterns-built/laravel/policies/POLICY-001-resource-policies.md` |
| Custom action methods (accept/deny/etc.) | `<PLUGIN_ROOT>/patterns-built/laravel/policies/POLICY-002-action-policies.md` |

## Process

1. Read the relevant pattern(s)
2. Scaffold: `php artisan make:policy {Model}Policy --model={Model} --no-interaction`
3. Implement standard CRUD + any custom action methods. ALL return `bool`. Delegate to model domain methods.
4. Auto-discovered (no manual registration)

## Return

- Policy file path
- Methods added (CRUD + custom)
- Wiring suggestion: authorize on the controller method (per POLICY-001 + the controller pattern), not on the route
