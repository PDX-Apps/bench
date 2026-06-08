---
mode: append
---

## Modular layout (this project uses laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- **Generate with** `php artisan module:make-model {Name} {Module}` (add `--all` for migration/factory/seeder/controller/request/resource/policy), never bare `make:model`.
- **File:** `Modules/{Module}/app/Models/{Name}.php`
- **Namespace:** `Modules\{Module}\Models`
- Reference related artifacts via their module namespaces (`Modules\{Module}\Database\Factories\...`).

Full structure + the artifact path/namespace table: `<PLUGIN_ROOT>/patterns-built/laravel/modules/MODULE-001-structure.md`.
