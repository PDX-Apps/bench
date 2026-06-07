---
concern: permissions
title: Permissions & roles
order: 30
detect: grep -q "spatie/laravel-permission" composer.json 2>/dev/null && echo spatie || echo policies
questions:
  - id: model
    ask: "What authorization model does this project use?"
    options: [spatie, gates, policies-only, custom]
    default: detect
  - id: roles
    ask: "Roles/permissions used (e.g. admin, member, billing.manage) — list the key ones, or 'none yet'."
    default: none yet
affects:
  - laravel/authorization/PERMISSION-001-model.md
output: overrides
---

## Apply

Write a `.bench/` override (mode `append`) of **PERMISSION-001-model.md** capturing the project's **authorization model** — the dedicated model file, distinct from the POLICY patterns (which stay about *how to write policies*):

- State the model `{model}` and how a check resolves:
  - `spatie` → `$user->can('permission')` / `$user->hasRole('role')`, roles + permissions in DB.
  - `gates` → `Gate::allows('ability')`; where gates are defined.
  - `policies-only` → resource policies + `#[Authorize]`, no role layer.
  - `custom` → describe the project's mechanism.
- List the project's roles/permissions (`{roles}`) so generated authz (policies, gates, `#[Authorize]`) uses the **real names**, not invented ones.

The base POLICY-001/002 patterns are untouched — they teach how to write a policy; this override teaches what to check.
