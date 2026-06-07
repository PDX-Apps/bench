---
overrides: base/http/controllers/CONTROLLER-001-resource.md
target: laravel-12
reason: Laravel 12 doesn't have first-party #[Middleware] and #[Authorize] controller attributes — use constructor authorizeResource() + route-level middleware groups.
base-hash: 03f8dd
---

> ⚠️ **Laravel 12 — no PHP-attribute controllers.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# CONTROLLER-001-resource

## Pattern

Thin resource controllers for **CRUD operations only**. Controllers handle HTTP concerns only. Two modes:

- **API** (default) — `Route::apiResource()`, **5 methods**, returns API Resources (JSON). No `create`/`edit` (no server-rendered forms).
- **Web (Blade)** — `Route::resource()`, **7 methods**, returns views and redirects. Adds `create()` and `edit()`, which render the form views.

The two share the same method names and authorization shape; they differ only in what each method returns (Resource/JSON vs. view/redirect) and whether the two form-rendering methods exist.

**Standard CRUD methods:**
- `index()` - List all
- `create()` - Show create form *(web only)*
- `store()` - Persist new
- `show()` - Show one
- `edit()` - Show edit form *(web only)*
- `update()` - Persist changes
- `destroy()` - Delete one

**Do NOT add custom methods to resource controllers.** If your feature requires non-CRUD endpoints, use a single-action (invokable) controller for one standalone endpoint, or a grouped controller for related non-CRUD endpoints.

## API Structure (Laravel 12 — constructor authorizeResource())

Laravel 12 has no `#[Middleware]` or `#[Authorize]` controller attributes. Authorization is wired in the constructor via `authorizeResource()`, which maps the CRUD methods to their policy abilities. Group-wide middleware lives on the route group (see the routing pattern), not the controller.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\{Model};
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class {Model}Controller extends Controller
{
    public function __construct()
    {
        $this->authorizeResource({Model}::class, '{model}');
    }

    public function index(): AnonymousResourceCollection
    {
        return {Model}Resource::collection({Model}::all());
    }

    public function store(
        Create{Model}Request $request,
        Create{Model}Action $action,
    ): {Model}Resource {
        $data = $request->toDto();
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
        $data = $request->toDto();
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

### How `authorizeResource()` maps abilities

`$this->authorizeResource({Model}::class, '{model}')` registers `can` middleware that maps each CRUD method to a policy ability automatically: `index` → `viewAny`, `store` → `create`, `show` → `view`, `update` → `update`, `destroy` → `delete`. The `'{model}'` argument names the route parameter bound to the model instance.

The mapping is implicit — readers can't see which method maps to which ability without knowing the convention. (The base/latest patterns surface it inline via `#[Authorize]`, but that's not available on L12.)

### Where shared middleware belongs

Don't declare the same guard in two places. Pick one home per concern:

- **Group-wide guards** that protect many controllers (`auth:sanctum`, `throttle:api`) — **the route group** (`Route::middleware('auth:sanctum')->group(...)`, see the routing pattern). One visible place for "what guards this whole section."
- **Controller- or action-specific** middleware (`subscribed` on one method) — declare it in the constructor with `$this->middleware('subscribed')->only('store')`.
- **Per-action authorization** — `authorizeResource()` in the constructor (above); it registers the `can` middleware for the CRUD methods.

Global middleware (CSRF, session) stays in `bootstrap/app.php`.

## Web (Blade) Structure

For server-rendered pages, the controller returns views and redirects instead of API Resources, and adds `create()` and `edit()` to render the form views. Authorization and Action delegation are unchanged.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\{Model};
use Illuminate\Contracts\View\View;
use Illuminate\Http\RedirectResponse;

class {Model}Controller extends Controller
{
    public function __construct()
    {
        $this->authorizeResource({Model}::class, '{model}');
    }

    public function index(): View
    {
        return view('{models}.index', ['{models}' => {Model}::paginate()]);
    }

    public function create(): View
    {
        return view('{models}.create');
    }

    public function store(Create{Model}Request $request, Create{Model}Action $action): RedirectResponse
    {
        $model = $action->execute($request->toDto());

        return redirect()->route('{models}.show', $model)->with('status', '{Model} created.');
    }

    public function show({Model} $model): View
    {
        return view('{models}.show', ['{model}' => $model]);
    }

    public function edit({Model} $model): View
    {
        return view('{models}.edit', ['{model}' => $model]);
    }

    public function update(Update{Model}Request $request, Update{Model}Action $action, {Model} $model): RedirectResponse
    {
        $action->execute($model, $request->toDto());

        return redirect()->route('{models}.show', $model)->with('status', '{Model} updated.');
    }

    public function destroy(Delete{Model}Action $action, {Model} $model): RedirectResponse
    {
        $action->execute($model);

        return redirect()->route('{models}.index')->with('status', '{Model} deleted.');
    }
}
```

Differences from the API variant:
- `create()` + `edit()` exist and return the form views
- Mutating methods return `RedirectResponse` (typically back to `show`/`index`) with a flash message, not a Resource
- `index()`/`show()` return a `View`; use `paginate()` for list views
- The route group middleware is usually `auth` (session guard) rather than `auth:sanctum`

## Key Points

- Extend `App\Http\Controllers\Controller` (still includes `AuthorizesRequests` and `ValidatesRequests` traits)
- **L12: Call `authorizeResource({Model}::class, '{model}')` in the constructor for automatic per-method policy authorization**
- **L12: Wire shared middleware on the route group; controller-specific middleware via `$this->middleware(...)` in the constructor**
- **CRUD methods only** — no custom methods (API: 5 methods; web adds `create`/`edit` for 7)
- Type hints on all parameters and returns
- Inject Action via method injection
- Get DTO via `$request->toDto()` on the FormRequest
- **API:** return an API Resource directly (Laravel wraps in 'data'); `{Model}Resource` for one, `AnonymousResourceCollection` for collections; only `destroy()` needs explicit `response()->json(null, 204)`
- **Web:** return a `View` for `index`/`create`/`show`/`edit`; return a `RedirectResponse` with a flash message for `store`/`update`/`destroy`
- No business logic in the controller
- Register with `Route::apiResource()` (API, 5 methods) or `Route::resource()` (web, 7 methods)

## When NOT to Use Resource Controllers

❌ **Don't add these to resource controllers:**
- Custom actions (join, accept, deny, cancel, verify)
- State transitions (activate, suspend, archive)
- Batch operations (bulk delete, import)
- Related sub-operations (invite member, transfer ownership)

✅ **Instead use:**
- An invokable controller for single standalone actions
- A grouped controller for related operations (max 4-5 methods)

## Route Registration

```php
// API — routes/api.php (5 methods, no create/edit)
Route::apiResource('orders', OrderController::class);

// Web — routes/web.php (7 methods, includes create/edit)
Route::resource('orders', OrderController::class);
```

Both generate route names `orders.index`, `orders.store`, etc. The `authorizeResource()` mapping applies during request handling — registration is unchanged. Use `only()`/`except()` to trim the method set (e.g. `Route::resource('orders', OrderController::class)->only(['index', 'show'])`).
