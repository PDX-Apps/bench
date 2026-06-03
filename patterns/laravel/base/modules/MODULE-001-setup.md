# MODULE-001-setup

## Pattern

Create and configure a new module using `nwidart/laravel-modules`.

## Create Module

```bash
php artisan module:make {ModuleName} --api
```

The `--api` flag prevents creation of vite assets and view-related files.

This creates the full module structure:
```
Modules/{ModuleName}/
├── Config/
├── Console/
├── Database/
│   ├── Factories/
│   ├── Migrations/
│   └── Seeders/
├── Entities/ (Models)
├── Http/
│   ├── Controllers/
│   ├── Middleware/
│   └── Requests/
├── Providers/
│   ├── {ModuleName}ServiceProvider.php
│   └── RouteServiceProvider.php
├── Resources/
│   ├── assets/
│   └── views/
├── Routes/
│   ├── api.php
│   └── web.php
├── Tests/
│   ├── Feature/
│   └── Unit/
├── composer.json
└── module.json
```

## Enable Module

```bash
php artisan module:enable {ModuleName}
```

## Common Module Commands

**Migration:**
```bash
php artisan module:make-migration create_{table}_table {ModuleName}
# Creates: Modules/{ModuleName}/Database/Migrations/{timestamp}_create_{table}_table.php
```

**Model:**
```bash
php artisan module:make-model {ModelName} {ModuleName}
# Creates: Modules/{ModuleName}/Entities/{ModelName}.php
```

**Controller:**
```bash
php artisan module:make-controller {ControllerName} {ModuleName} --api
# Creates: Modules/{ModuleName}/Http/Controllers/{ControllerName}.php
```

**Request:**
```bash
php artisan module:make-request {RequestName} {ModuleName}
# Creates: Modules/{ModuleName}/Http/Requests/{RequestName}.php
```

**Resource:**
```bash
php artisan module:make-resource {ResourceName} {ModuleName}
# Creates: Modules/{ModuleName}/Http/Resources/{ResourceName}.php
```

**Factory:**
```bash
php artisan module:make-factory {ModelName} {ModuleName}
# Creates: Modules/{ModuleName}/Database/Factories/{ModelName}Factory.php
# Note: Omit "Factory" suffix - see Known Issues below
```

**Seeder:**
```bash
php artisan module:make-seed {SeederName} {ModuleName}
# Creates: Modules/{ModuleName}/Database/Seeders/{SeederName}.php
```

**Test:**
```bash
php artisan module:make-test {TestName} {ModuleName}
# Creates: Modules/{ModuleName}/Tests/Feature/{TestName}.php
```

## Module Structure Customization

After creation, you may need to:
1. Create additional directories (Actions, Data, Events, Policies, Http/Resources)
2. Update the service provider to register policies, events, etc.
3. Configure routes in `Routes/api.php`

## Known Issues with Module Generators

**Factory naming bug:**
Omit the "Factory" suffix to avoid double-naming:
```bash
# Wrong - creates HouseholdFactoryFactory.php
php artisan module:make-factory HouseholdFactory Household

# Right - creates HouseholdFactory.php
php artisan module:make-factory Household Household
```

**Resource directory bug:**
Resources created in `Transformers/` instead of `Http/Resources/`:
```bash
# After creating resource, move it:
mv Modules/{Module}/app/Transformers/* Modules/{Module}/app/Http/Resources/
rmdir Modules/{Module}/app/Transformers
# Update namespace from Transformers to Http\Resources
```

**Test directory bug:**
Tests created in `Unit/` instead of `Feature/`:
```bash
# After creating test, move it:
mv Modules/{Module}/tests/Unit/* Modules/{Module}/tests/Feature/
# Update namespace from Tests\Unit to Tests\Feature
```

## Key Points

- Module name should be singular (Household, Budget, Expense)
- Always use `--api` flag to avoid vite assets
- Always create module before creating module resources
- Use module:make commands, not base artisan make commands
- Migrations automatically get timestamps
- Enable module after creation
