---
overrides: base/http/HTTP-001-resource-controllers.md
target: laravel-12
reason: Laravel 12 doesn't have first-party #[Middleware] and #[Authorize] controller attributes — use constructor authorizeResource() + route-level middleware groups.
base-hash: da3220
---

> ⚠️ **Laravel 12 — no PHP-attribute controllers.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# HTTP-001-resource-controllers

## Pattern

Thin API resource controllers for **CRUD operations only**. Controllers handle HTTP concerns only.

**IMPORTANT:** Resource controllers contain ONLY the 5 standard CRUD methods:
- `index()` - List all
- `store()` - Create new
- `show()` - Get one
- `update()` - Update one
- `destroy()` - Delete one

**Do NOT add custom methods to resource controllers.** If your feature requires non-CRUD endpoints, use:
- `HTTP-005-invokable-controllers` - Single-action endpoints (e.g., `/verify-email`)
- `HTTP-006-grouped-controllers` - Related non-CRUD endpoints (e.g., invitation accept/deny/cancel)

## Dependencies

- `http/HTTP-002-form-requests.md` - FormRequests with validation
- `http/HTTP-003-api-resources.md` - API Resources for responses
- `http/HTTP-005-invokable-controllers.md` - Single-action controllers
- `http/HTTP-006-grouped-controllers.md` - Grouped non-CRUD controllers
- `policies/POLICY-001-resource-policies.md` - Authorization policies
- `dto/DTO-001-request-data.md` - Data Transfer Objects
- `code/CODE-002-swagger.md` - OpenAPI documentation annotations

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Controllers;

use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class {Model}Controller extends Controller
{
    public function __construct()
    {
        $this->authorizeResource({Model}::class, '{model}');
    }

    public function index(): AnonymousResourceCollection
    {
        $models = {Model}::all();

        return {Model}Resource::collection($models);
    }

    public function store(
        Create{Model}Request $request,
        Create{Model}Action $action,
    ): {Model}Resource {
        $data = $request->toData();
        $model = $action->execute($data);

        return new {Model}Resource($model);
    }

    public function show({Model} $model): {Model}Resource
    {
        return new {Model}Resource($model);
    }

    public function update(
        Update{Model}Request $request,
        Update{Model}Action $action,
        {Model} $model,
    ): {Model}Resource {
        $data = $request->toData();
        $updated = $action->execute($model, $data);

        return new {Model}Resource($updated);
    }

    public function destroy(
        Delete{Model}Action $action,
        {Model} $model,
    ): JsonResponse {
        $action->execute($model);

        return response()->json(null, 204);
    }
}
```

## Key Points

- Extend `App\Http\Controllers\Controller` (includes AuthorizesRequests and ValidatesRequests traits)
- Call `authorizeResource()` in constructor for automatic policy authorization
- **CRUD methods only** (index, store, show, update, destroy) - no custom methods
- Type hints on all parameters and returns
- Inject Action via method injection
- Get DTO via `$request->toData()` (see HTTP-002-form-requests)
- Return API Resource directly - Laravel wraps in 'data' key automatically
- Return type: `{Model}Resource` for single resource, `AnonymousResourceCollection` for collections
- Only `destroy()` needs explicit `response()->json()` for 204 status
- No business logic in the controller
- Register with `Route::apiResource()`

## When NOT to Use Resource Controllers

❌ **Don't add these to resource controllers:**
- Custom actions (join, accept, deny, cancel, verify)
- State transitions (activate, suspend, archive)
- Batch operations (bulk delete, import)
- Related sub-operations (invite member, transfer ownership)

✅ **Instead use:**
- `HTTP-005-invokable-controllers` for single standalone actions
- `HTTP-006-grouped-controllers` for related operations (max 4-5 methods)

## Route Registration

```php
// routes/api.php or Module route file
Route::apiResource('households', HouseholdController::class);
```
