# ROUTE-001

## Pattern

Route files map URLs to controllers and apply **shared, group-wide middleware**. They do not
carry per-action authorization — that lives on the controller via `#[Authorize]` (see the
controller pattern). A route file should read as "what's reachable and what guards the whole
section," not "who can do each thing."

## Route Files

- **`routes/api.php`** — stateless/token or SPA APIs. Returns JSON (API Resources).
- **`routes/web.php`** — server-rendered (Blade) pages. Returns views and redirects.

Pick the file by what the controller returns, not by a blanket rule. An API resource controller
goes in `api.php`; a Blade resource controller goes in `web.php`.

## Resource Routes

```php
use App\Http\Controllers\OrderController;

// API — routes/api.php (5 methods: index, store, show, update, destroy)
Route::apiResource('orders', OrderController::class);

// Web — routes/web.php (7 methods: adds create, edit)
Route::resource('orders', OrderController::class);
```

Laravel auto-generates route names (`orders.index`, `orders.store`, …). Trim the set with
`->only([...])` / `->except([...])`.

## Shared Middleware Belongs on the Group

Apply guards that protect a whole section once, on the route group — the single visible place
for "what protects everything here":

```php
// routes/api.php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('orders', OrderController::class);
    Route::apiResource('subscriptions', SubscriptionController::class);
});
```

```php
// routes/web.php
Route::middleware(['auth'])->group(function () {
    Route::resource('orders', OrderController::class);
});
```

A class-level `#[Middleware('auth:sanctum')]` on the controller is an equivalent alternative —
but never declare the same guard in both places (Laravel dedupes it, but two declarations means
two sources of truth). Pick one home per guard.

## Non-CRUD / Invokable Routes

Map the URL to an invokable (or grouped) controller. Authorization for the action lives on the
controller method (`#[Authorize('markPaid', 'order')]`), **not** on the route:

```php
// routes/api.php — mapping only, no ->can()
Route::post('orders/{order}/mark-paid', MarkOrderPaidController::class)
    ->name('orders.mark-paid');
```

## Authorization Does NOT Go Here

Do **not** use `->can()` on routes or `authorizeResource()` in the controller constructor.
Per-action authorization is the `#[Authorize]` attribute on the controller method — it *is* the
`can` middleware, so adding `->can()` as well would declare the same gate twice.

```php
// ❌ don't
Route::post('orders/{order}/mark-paid', MarkOrderPaidController::class)
    ->can('markPaid', 'order');

// ✅ do — authorize on the controller action
#[Authorize('markPaid', 'order')]
public function __invoke(Order $order) { /* ... */ }
```

## Route Model Binding

Use the implicit binding parameter that matches the type-hint (`{order}` → `Order $order`).
By default this resolves by primary key; override `getRouteKeyName()` on the model to bind by a
different column.

```php
Route::apiResource('orders', OrderController::class);
// show(Order $order) receives the resolved model
```

## Key Points

- Route files = URL → controller mapping + **shared group middleware** only
- Choose `api.php` (JSON) vs `web.php` (Blade views) by what the controller returns
- `Route::apiResource()` (5 methods) for API CRUD; `Route::resource()` (7) for web CRUD
- Group-wide guards (`auth:sanctum`, `throttle`) go on the **route group** (or a class-level `#[Middleware]` — never both)
- **No authorization in route files** — no `->can()`, no `authorizeResource()`; use `#[Authorize]` on the controller method
- Always `->name(...)` non-resource routes; resource routes are auto-named
- Implicit model binding by type-hint; `getRouteKeyName()` to bind by another column
