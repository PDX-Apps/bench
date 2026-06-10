# Authorization model — permissions & roles

The project's **authorization model**: who can do what, and where that decision lives. This is distinct from *writing* the policy classes — this documents **what the policies/gates actually check**.

## The question this answers

"Can this user perform this action?" — and where the answer is defined. Generated authorization (controllers, policies, gates) must consult **this model**, not hard-code role strings.

## Bench default (no roles package)

- **Per-action authorization** via `#[Authorize]` on controller actions, backed by **Policy** classes for resource-owned authz.
- **Gates** for non-resource, app-wide abilities (`Gate::define('manage-billing', …)`).
- Coarse role distinctions via a `role` enum/column on the user, checked inside policies/gates — never inline in controllers.

## Common project models — capture yours with `/bench-configure permissions`

| Model | How a check resolves | Fits |
|-------|----------------------|------|
| **spatie/laravel-permission** | `$user->can('invoices.manage')` / `$user->hasRole('admin')`; roles + permissions in DB | teams needing dynamic, data-driven roles |
| **Gates** | `Gate::allows('ability')`, abilities defined in a service provider | small/medium apps, a handful of abilities |
| **Policies-only** | resource policies + `#[Authorize]`; no role layer | resource-centric apps |
| **Enum roles** | a `UserRole` enum, checked in policies/gates (`$user->role === UserRole::Admin`) | fixed, small role sets |

A project's `.bench/` override of this file (written by the `permissions` concern) names the project's actual model, roles, and permission names.

## How it's consulted

- **Controllers** authorize per action (`#[Authorize]`) — they don't decide; they ask.
- **Policies / gates** call into the model (`$user->can(...)`, `hasRole()`, the enum). Centralize abilities; reference permissions by stable names (`invoices.view`, `invoices.manage`), not scattered literals.
- **The model is one source of truth** — adding an ability means defining it once (a gate, a spatie permission, an enum case), then referencing it.

## Don't

- Don't scatter raw role checks (`if ($user->role === 'admin')`) across controllers/views — centralize in policies/gates/the model.
- Don't conflate the **model** (this file — *what* is checked) with **writing a policy** (*how*).
- Don't invent permission names ad hoc — use the project's established ones.
