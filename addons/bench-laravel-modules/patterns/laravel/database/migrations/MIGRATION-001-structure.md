---
mode: append
---

## Modular layout (this project uses bench-laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- **Generate with** `php artisan module:make-migration {description} {Module}`, never bare `make:migration`.
- **File:** `Modules/{Module}/database/migrations/{timestamp}_{description}.php`
- Migration classes stay anonymous/un-namespaced, exactly as in core.
- The module's service provider auto-loads migrations from this path (`loadMigrationsFrom`); run them with `php artisan module:migrate {Module}` or the global `migrate`.

Full structure + the artifact path/namespace table: `<PLUGIN_ROOT>/patterns-built/laravel/modules/MODULE-001-structure.md`.
