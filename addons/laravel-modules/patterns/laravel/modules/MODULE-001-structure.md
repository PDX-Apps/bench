# MODULE-001-structure

## Pattern

Organize the app into self-contained **modules** with [`nwidart/laravel-modules`](https://github.com/nWidart/laravel-modules). Each module is a mini-app under `Modules/{Module}/` with its own controllers, models, migrations, routes, config, and service providers — the inverse of bench's default flat `app/` layout. When this addon is active, all generated artifacts go inside the relevant module.

**Install:**
```bash
composer require nwidart/laravel-modules
php artisan vendor:publish --provider="Nwidart\Modules\LaravelModulesServiceProvider"
```

Autoloading: add the module namespace to `composer.json` `autoload.psr-4` (`"Modules\\": "Modules/"`) and run `composer dump-autoload` — the published config does most of this.

## Create a module

```bash
php artisan module:make Catalog
```

Module names are **singular, PascalCase** (`Catalog`, `Billing`, `Subscription`). This scaffolds (current nwidart layout, with an inner `app/`):

```
Modules/
└── Catalog/
    ├── app/
    │   ├── Http/Controllers/CatalogController.php
    │   ├── Models/
    │   └── Providers/
    │       ├── CatalogServiceProvider.php
    │       └── RouteServiceProvider.php
    ├── config/config.php
    ├── database/
    │   ├── factories/
    │   ├── migrations/
    │   └── seeders/
    ├── resources/{assets,views}/
    ├── routes/{web.php,api.php}
    ├── tests/{Feature,Unit}/
    ├── composer.json
    └── module.json
```

Everything in `Modules/{Module}/app/` maps to namespace `Modules\{Module}\...` (e.g. `app/Models/Product.php` → `Modules\Catalog\Models\Product`).

## Generate artifacts inside the module

Always use the `module:make-*` generators (not bare `make:*`) and pass the module name as the **last** argument:

```bash
php artisan module:make-model Product Catalog            # app/Models/Product.php
php artisan module:make-model Product Catalog --all      # + migration, factory, seeder, controller, request, resource, policy
php artisan module:make-controller ProductController Catalog --api
php artisan module:make-controller Api/ProductController Catalog        # subdirectory
php artisan module:make-migration create_products_table Catalog
php artisan module:make-request StoreProductRequest Catalog
php artisan module:make-resource ProductResource Catalog
php artisan module:make-factory ProductFactory Catalog
php artisan module:make-seed ProductSeeder Catalog
php artisan module:make-policy ProductPolicy Catalog
php artisan module:make-middleware EnsureSubscribed Catalog
php artisan module:make-event EventName Catalog
php artisan module:make-listener ListenerName Catalog
php artisan module:make-job JobName Catalog
php artisan module:make-command CommandName Catalog
```

### Where each artifact lands (under `Modules/{Module}/`)

| Artifact | Path | Namespace |
|----------|------|-----------|
| Model | `app/Models/{Name}.php` | `Modules\{Module}\Models` |
| Controller | `app/Http/Controllers/{Name}.php` | `Modules\{Module}\Http\Controllers` |
| Request | `app/Http/Requests/{Name}.php` | `Modules\{Module}\Http\Requests` |
| Resource | `app/Transformers/{Name}.php`¹ | `Modules\{Module}\Transformers` |
| Middleware | `app/Http/Middleware/{Name}.php` | `Modules\{Module}\Http\Middleware` |
| Policy | `app/Policies/{Name}.php` | `Modules\{Module}\Policies` |
| Service / Action | `app/Services/{Name}.php` (create dir) | `Modules\{Module}\Services` |
| Migration | `database/migrations/{ts}_*.php` | (no namespace) |
| Factory | `database/factories/{Name}Factory.php` | `Modules\{Module}\Database\Factories` |
| Seeder | `database/seeders/{Name}.php` | `Modules\{Module}\Database\Seeders` |
| Routes | `routes/api.php`, `routes/web.php` | — |
| Config | `config/config.php` | — |

¹ The resource path is configurable in `config/modules.php` (`paths.generator.resource`); some setups emit to `app/Http/Resources`. Match whatever your project already uses.

## Service providers + routes

`module:make` generates a `{Module}ServiceProvider` (registers config, views, translations, migrations) and a `RouteServiceProvider` (loads `routes/api.php` + `routes/web.php`). Register additional bindings, policies, events, and observers in the module's service provider — keep cross-module wiring out of the global `app/Providers`.

## Conventions

- One module = one bounded context (Catalog, Billing, Subscription). Don't reach into another module's internals; depend on its public services/events.
- Singular PascalCase module names.
- Always generate with `module:make-*`; create a module before generating into it (`php artisan module:make {Module}` first).
- Verify the exact generated paths against `config/modules.php` — nwidart lets projects relocate any generator path, and these can drift between versions.

## Key Points

- Modules live in `Modules/{Module}/`, code under the inner `app/`, namespace `Modules\{Module}\...`.
- Use the `module:make-*` generators — never bare `make:*` — with the module name as the last argument.
- Each module owns its routes, config, and service providers.
- This pattern is the layout source of truth; the per-artifact core patterns append a "Modular layout" note that points back here.
