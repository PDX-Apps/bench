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
  - laravel/policies/POLICY-001-resource-policies.md
  - laravel/policies/POLICY-002-action-policies.md
output: overrides
---

## Apply

Write `.bench/patterns/...` overrides (mode `append`) capturing the project's **authorization model** (distinct from *how to write a policy* — that stays in the base POLICY patterns):

- **POLICY-001 / POLICY-002** — how checks resolve for `{model}`:
  - `spatie` → policies/gates consult `$user->can('permission')` / `hasRole()` backed by spatie's tables; name the key roles/permissions from `{roles}`.
  - `gates` → checks via `Gate::define`/`Gate::allows`; where gates live.
  - `policies-only` → standard policy classes; no role layer.
  - `custom` → describe the project's mechanism.
- List the project's roles/permissions (`{roles}`) so generated authz uses the real names.

(Idea: a dedicated `permissions` PATTERN file — the *model* — separate from POLICY files. Until then, this concern appends to the policy patterns. See working-notes.)
