# laravel-modules

Make bench **modular-aware** for projects built on [`nwidart/laravel-modules`](https://github.com/nWidart/laravel-modules) — code organized under `Modules/{Module}/` instead of a flat `app/`.

This is the **inverse of bench's default**, which de-modularizes generated code into a flat `app/` layout. Install this addon only on projects that actually use nwidart modules; once active, bench's agents generate every artifact inside the relevant module (`Modules/{Module}/app/...`, namespace `Modules\{Module}\...`).

## What it ships

- **MODULE-001 — structure** (`patterns/laravel/modules/`) — the canonical module layout: `module:make` + the `module:make-*` generators, where each artifact type lives, and how routes / config / service providers are wired. Layout source of truth.
- **Append overrides** (`mode: append`) onto representative core patterns so generated code matches the module layout:
  - `models/MODEL-001-structure` → `Modules/{Module}/app/Models`
  - `database/migrations/MIGRATION-001-structure` → `Modules/{Module}/database/migrations`
  - `http/controllers/CONTROLLER-001-resource` → `Modules/{Module}/app/Http/Controllers`
  - `services/SERVICE-002-domain-services` → `Modules/{Module}/app/Services`
  Each appends a short "Modular layout" note that points back at MODULE-001.
- **`/module`** skill + **`module`** agent — scaffold a new module (`php artisan module:make`) and optionally seed its first artifacts, verifying the generated paths + namespaces.

## Install

```bash
bench addon add /path/to/bench/addons/laravel-modules
bench rebuild
```

Then `/module Catalog with a Product model (--all) and an Api/ProductController`.

## Notes

- Module names are singular PascalCase (`Catalog`, `Billing`, `Subscription`).
- nwidart lets projects relocate any generator path via `config/modules.php`; the patterns and agent verify against the project's actual config rather than assuming defaults.
- One module = one bounded context. Depend on another module's public services/events, not its internals.
