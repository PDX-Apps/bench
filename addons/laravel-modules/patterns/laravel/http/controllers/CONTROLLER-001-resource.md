---
mode: append
---

## Modular layout (this project uses laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- **Generate with** `php artisan module:make-controller {Name} {Module} --api` (drop `--api` for the 7-method web variant; use `Api/{Name}` for a subdirectory), never bare `make:controller`.
- **File:** `Modules/{Module}/app/Http/Controllers/{Name}.php`
- **Namespace:** `Modules\{Module}\Http\Controllers`
- Register routes in the module's `routes/api.php` / `routes/web.php` (loaded by the module's `RouteServiceProvider`), not the global route files.
- Form Requests and API Resources resolve from the same module namespace.

Generate inside the relevant module (`Modules/{Module}/...`) with the `Modules\{Module}\...` namespace.
