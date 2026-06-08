# PERMISSION-002-spatie

**spatie/laravel-permission** — the concrete implementation of the authorization model documented in [PERMISSION-001-model](PERMISSION-001-model.md). Roles and permissions live in the database; the authenticatable model carries the `HasRoles` trait; checks go through `can()` / `hasRole()`, Blade `@can`, and route middleware.

## Pattern

### HasRoles on the authenticatable

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Spatie\Permission\Traits\HasRoles;

class User extends Authenticatable
{
    use HasRoles;

    // ...
}
```

---

### Define permissions + roles in a seeder

All permission and role names are defined once in a seeder — they are the single source of truth. Never scatter string literals across the codebase.

```php
<?php

declare(strict_types=1);

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Permission;
use Spatie\Permission\Models\Role;
use Spatie\Permission\PermissionRegistrar;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        // Reset cached roles and permissions before seeding.
        app(PermissionRegistrar::class)->forgetCachedPermissions();

        // Permissions — use stable dotted names.
        $viewInvoices   = Permission::firstOrCreate(['name' => 'invoices.view']);
        $manageInvoices = Permission::firstOrCreate(['name' => 'invoices.manage']);
        $refundOrders   = Permission::firstOrCreate(['name' => 'orders.refund']);
        $viewReports    = Permission::firstOrCreate(['name' => 'reports.view']);

        // Roles — assign permissions at definition time.
        $viewer = Role::firstOrCreate(['name' => 'viewer']);
        $viewer->syncPermissions([$viewInvoices, $viewReports]);

        $manager = Role::firstOrCreate(['name' => 'manager']);
        $manager->syncPermissions([$viewInvoices, $manageInvoices, $viewReports]);

        $admin = Role::firstOrCreate(['name' => 'admin']);
        $admin->syncPermissions([$viewInvoices, $manageInvoices, $refundOrders, $viewReports]);

        Role::firstOrCreate(['name' => 'super-admin']);
        // super-admin bypasses all checks via Gate::before — no explicit permissions needed.
    }
}
```

Register in `DatabaseSeeder`:

```php
$this->call(RolesAndPermissionsSeeder::class);
```

---

### Checking permissions

**Controllers / service classes**

```php
// Gate / can() — preferred for policy-style checks.
$this->authorize('invoices.manage'); // throws 403 if denied

// Direct check.
if ($user->can('invoices.manage')) { ... }
if ($user->hasRole('admin')) { ... }
```

**Blade**

```blade
@can('invoices.manage')
    <a href="{{ route('invoices.create') }}">New invoice</a>
@endcan

@hasrole('admin')
    <x-admin-panel />
@endhasrole
```

**Route middleware**

```php
Route::middleware('permission:invoices.manage')->group(function () {
    Route::post('/invoices', [InvoiceController::class, 'store']);
});

Route::middleware('role:admin')->group(function () {
    Route::get('/admin', [AdminController::class, 'index']);
});

// Role OR permission — either suffices.
Route::middleware('role_or_permission:admin|invoices.manage')->group(...);
```

---

### Super-admin via Gate::before

Register in `AuthServiceProvider` (or `AppServiceProvider` in Laravel 11+):

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use Illuminate\Support\Facades\Gate;
use Illuminate\Foundation\Support\Providers\AuthServiceProvider as ServiceProvider;

class AuthServiceProvider extends ServiceProvider
{
    public function boot(): void
    {
        Gate::before(function ($user, string $ability): ?bool {
            if ($user->hasRole('super-admin')) {
                return true; // short-circuits ALL Gate checks
            }

            return null; // fall through to normal checks
        });
    }
}
```

> **Caveat:** `Gate::before` returning `true` bypasses every policy and gate definition, including `before` hooks defined elsewhere. Use only for a genuine super-admin escape hatch.

---

### Guards + teams (brief)

- Permissions are **guard-aware** — a permission belongs to one guard (`web`, `api`, etc.). When using multiple guards, specify the guard when assigning permissions or set `permission_default_guard` in the spatie config.
- **Teams** feature (`teams = true` in `config/permission.php`) scopes roles + permissions to a team ID. Useful for multi-tenant apps; requires the `team_id` foreign key on the pivot tables. Consult the spatie docs before enabling — it's a one-way migration.

---

### Caching

spatie caches the full permission table in the default cache store. After **any programmatic change** (seeder, `Permission::create()`, `$role->givePermissionTo()`), reset the cache:

```php
app(PermissionRegistrar::class)->forgetCachedPermissions();
```

In production, if you sync permissions via a seeder (`php artisan db:seed --class=RolesAndPermissionsSeeder`), the cache is reset inside the seeder. For queued jobs that assign permissions, call `forgetCachedPermissions()` at the start of the job.

---

## Anti-patterns

- **Raw role-string checks in controllers/views** — `if ($user->role === 'admin')` bypasses the permission system and scatters authorization logic. Use `$user->hasRole()` or `$user->can()` and keep logic in policies/gates.
- **Checking roles where a permission is more stable** — roles change shape over time; permissions (`invoices.manage`) are more granular and survive role restructuring.
- **Defining permissions inline** — `Permission::create(['name' => 'invoices.manage'])` scattered in controllers, tests, or factories means no single source of truth. All permission definitions belong in the seeder.
- **Forgetting to reset the cache** after programmatic permission changes; the app will serve stale data until the TTL expires.

---

## Key Points

- `HasRoles` goes on the authenticatable model (typically `User`).
- All permission + role names live in `RolesAndPermissionsSeeder`; they are stable dotted strings (`resource.action`).
- Call `app(PermissionRegistrar::class)->forgetCachedPermissions()` before any batch seeding.
- `Gate::before` returning `true` for `super-admin` is the standard escape hatch — it short-circuits everything.
- Prefer `can('permission.name')` over `hasRole('role-name')` in application code; roles are an admin concept, permissions are the contract.
- Middleware options: `permission:name`, `role:name`, `role_or_permission:role|permission`.
- Guards and teams are supported but add complexity — configure in `config/permission.php` and document in the project's `permissions` concern.
