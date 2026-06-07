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

## API Structure (Laravel 13 — attribute-based)

Laravel 13 ships first-party `#[Middleware]` and `#[Authorize]` attributes for controllers. Prefer them over the constructor-based `authorizeResource()` and middleware bootstrap — the policy mapping lives at the method declaration where it's discoverable.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\{Model};
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Routing\Attributes\Controllers\Middleware;

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
        $data = $request->toDto();
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
        $data = $request->toDto();
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

### Where shared middleware belongs

Don't declare the same guard in two places. Pick one home per concern:

- **Group-wide guards** that protect many controllers (`auth:sanctum`, `throttle:api`) — **prefer the route group** (`Route::middleware('auth:sanctum')->group(...)`, see the routing pattern). One visible place for "what guards this whole section." A class-level `#[Middleware('auth:sanctum')]` is an equivalent option if you'd rather keep it on the controller — just don't do both (Laravel dedupes middleware, but two declarations means two sources of truth).
- **Controller- or action-specific** middleware (`subscribed` on one method) — the `#[Middleware]` attribute, co-located with the code.
- **Per-action authorization** — the `#[Authorize]` attribute (below). It *is* the `can` middleware; never also add `->can()` on the route for the same action.

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
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('auth')]
class {Model}Controller extends Controller
{
    #[Authorize('viewAny', {Model}::class)]
    public function index(): View
    {
        return view('{models}.index', ['{models}' => {Model}::paginate()]);
    }

    #[Authorize('create', {Model}::class)]
    public function create(): View
    {
        return view('{models}.create');
    }

    #[Authorize('create', {Model}::class)]
    public function store(Create{Model}Request $request, Create{Model}Action $action): RedirectResponse
    {
        $model = $action->execute($request->toDto());

        return redirect()->route('{models}.show', $model)->with('status', '{Model} created.');
    }

    #[Authorize('view', '{model}')]
    public function show({Model} $model): View
    {
        return view('{models}.show', ['{model}' => $model]);
    }

    #[Authorize('update', '{model}')]
    public function edit({Model} $model): View
    {
        return view('{models}.edit', ['{model}' => $model]);
    }

    #[Authorize('update', '{model}')]
    public function update(Update{Model}Request $request, Update{Model}Action $action, {Model} $model): RedirectResponse
    {
        $action->execute($model, $request->toDto());

        return redirect()->route('{models}.show', $model)->with('status', '{Model} updated.');
    }

    #[Authorize('delete', '{model}')]
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
- Middleware is usually `auth` (session guard) rather than `auth:sanctum`

## Key Points

- Extend `App\Http\Controllers\Controller` (still includes `AuthorizesRequests` and `ValidatesRequests` traits)
- **L13: Use `#[Authorize('ability', Model::class)]` per method instead of `authorizeResource()` in constructor**
- **L13: Use `#[Middleware('name')]` at class or method level instead of constructor middleware**
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

Both generate route names `orders.index`, `orders.store`, etc. The `#[Authorize]` attributes apply during request handling — registration is unchanged. Use `only()`/`except()` to trim the method set (e.g. `Route::resource('orders', OrderController::class)->only(['index', 'show'])`).
