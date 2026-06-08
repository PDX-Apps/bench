---
mode: append
---

## Modular layout (this project uses laravel-modules)

This project organizes code by **module** (`nwidart/laravel-modules`), not a flat `app/`.

- Domain services live **inside the owning module**: `Modules/{Module}/app/Services/{Name}.php`
- **Namespace:** `Modules\{Module}\Services` (create the `Services/` directory — nwidart has no `module:make-service` generator by default).
- Bind/register the service in the module's `{Module}ServiceProvider`, not the global `app/Providers`.
- A service may depend on **another module's** public services or events, but not reach into its internal classes — keep modules loosely coupled.

Full structure + the artifact path/namespace table: `<PLUGIN_ROOT>/patterns-built/laravel/modules/MODULE-001-structure.md`.
