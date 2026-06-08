---
name: permission
description: Scaffold a spatie/laravel-permission role or permission across the project — HasRoles trait, seeder entry, and any requested middleware/policy wiring. Reads PERMISSION-002-spatie.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You scaffold ONE permission or role using spatie/laravel-permission. The skill provided enriched context. Read only what you need.

## Pattern Lookup

| Need | Read |
|------|------|
| spatie HasRoles trait, seeder structure, middleware, super-admin Gate::before | `<PLUGIN_ROOT>/patterns-built/laravel/authorization/PERMISSION-002-spatie.md` |
| Authorization model — what roles/permissions exist in this project | `<PLUGIN_ROOT>/patterns-built/laravel/authorization/PERMISSION-001-model.md` |

## Process

1. **Read the pattern** (PERMISSION-002-spatie).
2. **Check the authenticatable model** — grep for `HasRoles`. If missing, add `use Spatie\Permission\Traits\HasRoles;` and wire the trait. Match the project's model location (detect from existing files; do not assume `app/Models/User.php` if the layout differs).
3. **Add to the seeder** — locate `RolesAndPermissionsSeeder` (or equivalent). If absent, create it at `database/seeders/RolesAndPermissionsSeeder.php` following the pattern. Add the requested permission(s)/role(s) using `Permission::firstOrCreate` / `Role::firstOrCreate` with stable dotted names (`resource.action`). Call `app(PermissionRegistrar::class)->forgetCachedPermissions()` at the top of `run()`.
4. **Wire enforcement** — if the skill context names a route, controller action, or Blade location to protect, add the appropriate middleware / `$this->authorize()` / `@can` call. Reference the permission by name, not the role.
5. **Use real names** — the project's `.bench/` captured names (from the `permissions` concern) are the source of truth. Use those names; never invent new ones without noting it as a follow-up for the user to confirm.

## Return

- Files touched (model, seeder, any route/controller/Blade file).
- Permission and role names added.
- Seeder path + reminder to run: `php artisan db:seed --class=RolesAndPermissionsSeeder`.
- Any follow-ups: publish spatie migrations (`php artisan vendor:publish --provider="Spatie\Permission\PermissionServiceProvider"`), confirm new permission names with team, cache reset.

## Anti-patterns

- Do not invent permission names that aren't in the project's established set without flagging them as new.
- Do not add raw role-string checks (`$user->role === 'admin'`); always use `$user->hasRole()` or `$user->can()`.
- Do not edit files beyond: the authenticatable model, the roles-and-permissions seeder, and the specific route/controller/Blade file named in the request.
- Do not hardcode the namespace or directory prefix for models or seeders — detect from the project's actual layout.
