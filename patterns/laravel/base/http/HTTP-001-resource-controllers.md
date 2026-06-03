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

## Structure (Laravel 13 — attribute-based)

Laravel 13 ships first-party `#[Middleware]` and `#[Authorize]` attributes for controllers. Prefer them over the constructor-based `authorizeResource()` and middleware bootstrap — the policy mapping lives at the method declaration where it's discoverable.

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Controllers;

use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Routing\Attributes\Controllers\Middleware;
use Modules\{Module}\Models\{Model};

#[Middleware('auth:sanctum')]
class {Model}Controller extends Controller
{
    #[Authorize('viewAny', {Model}::class)]
    public function index(): AnonymousResourceCollection
    {
        return {Model}Resource::collection({Model}::all());
    }

    #[Authorize('create', {Model}::class)]
    public function store(
        Create{Model}Request $request,
        Create{Model}Action $action,
    ): {Model}Resource {
        $data = $request->toData();
        $model = $action->execute($data);

        return new {Model}Resource($model);
    }

    #[Authorize('view', '{model}')]
    public function show({Model} $model): {Model}Resource
    {
        return new {Model}Resource($model);
    }

    #[Authorize('update', '{model}')]
    public function update(
        Update{Model}Request $request,
        Update{Model}Action $action,
        {Model} $model,
    ): {Model}Resource {
        $data = $request->toData();
        $updated = $action->execute($model, $data);

        return new {Model}Resource($updated);
    }

    #[Authorize('delete', '{model}')]
    public function destroy(
        Delete{Model}Action $action,
        {Model} $model,
    ): JsonResponse {
        $action->execute($model);

        return response()->json(null, 204);
    }
}
```

### Why Attributes Over `authorizeResource()`

The L12 idiom required a constructor:
```php
public function __construct()
{
    $this->authorizeResource({Model}::class, '{model}');
}
```
…which hides the policy mapping in framework magic. Readers don't see which method maps to which policy ability.

The L13 idiom puts `#[Authorize('create', ...)]` directly on the method. Reading the controller, you see the policy ability for each endpoint inline. Static analysis tools can also resolve the policy reference.

Both still work. The attribute form is preferred for new code.

### `#[Middleware]` Attribute

Class-level for "applies to every method":
```php
#[Middleware('auth:sanctum')]
#[Middleware('throttle:api')]
class {Model}Controller extends Controller {}
```

Method-level for "this method only":
```php
#[Middleware('subscribed')]
public function store() { }
```

This replaces middleware groups defined in `bootstrap/app.php` for controller-specific cases. Global middleware (CSRF, session) still lives in `bootstrap/app.php`.

## Key Points

- Extend `App\Http\Controllers\Controller` (still includes `AuthorizesRequests` and `ValidatesRequests` traits)
- **L13: Use `#[Authorize('ability', Model::class)]` per method instead of `authorizeResource()` in constructor**
- **L13: Use `#[Middleware('name')]` at class or method level instead of constructor middleware**
- **CRUD methods only** (index, store, show, update, destroy) — no custom methods
- Type hints on all parameters and returns
- Inject Action via method injection
- Get DTO via `$request->toData()` (see HTTP-002-form-requests)
- Return API Resource directly — Laravel wraps in 'data' key automatically
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

Routes still use `apiResource()` — the attributes apply during request handling, route registration is unchanged.
