---
mode: append
---

## Modular layout (this project uses laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- **Generate with** `php artisan module:make-migration {description} {Module}`, never bare `make:migration`.
- **File:** `Modules/{Module}/database/migrations/{timestamp}_{description}.php`
- Migration classes stay anonymous/un-namespaced, exactly as in core.
- The module's service provider auto-loads migrations from this path (`loadMigrationsFrom`); run them with `php artisan module:migrate {Module}` or the global `migrate`.

Generate inside the relevant module (`Modules/{Module}/...`) with the `Modules\{Module}\...` namespace.
