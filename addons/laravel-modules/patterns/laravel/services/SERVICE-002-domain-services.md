---
mode: append
---

## Modular layout (this project uses laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- Domain services live **inside the owning module**: `Modules/{Module}/app/Services/{Name}.php`
- **Namespace:** `Modules\{Module}\Services` (create the `Services/` directory — nwidart has no `module:make-service` generator by default).
- Bind/register the service in the module's `{Module}ServiceProvider`, not the global `app/Providers`.
- A service may depend on **another module's** public services or events, but not reach into its internal classes — keep modules loosely coupled.

Generate inside the relevant module (`Modules/{Module}/...`) with the `Modules\{Module}\...` namespace.
