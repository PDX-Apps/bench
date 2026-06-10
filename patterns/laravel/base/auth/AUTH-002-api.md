# AUTH-002-api

## Pattern

Token-based authentication using Laravel Sanctum for SPAs, mobile apps, and external API consumers. Stateless — each request carries a bearer token; no session cookie or CSRF token.

## When to use

- SPAs that hit the Laravel backend across domains or with token-based auth
- Mobile applications
- Third-party API integrations
- Service-to-service calls

For server-rendered web apps with session cookies.

## Setup

```bash
composer require laravel/sanctum
php artisan vendor:publish --tag=sanctum-config
php artisan migrate
```

## Middleware

Routes are wrapped with the `auth:sanctum` middleware:

```php
Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('orders', OrderController::class);
});
```

`Route::apiResource` registers 5 routes (index, show, store, update, destroy) — no view-returning `create` / `edit`.

## Client authentication

- Issue a token: `$user->createToken('token-name')->plainTextToken`
- Client sends it on every request:
  ```
  Authorization: Bearer {token}
  ```

## Accessing the current user

Inside the controller:
- `$request->user()` — current authenticated user (the Sanctum guard resolves it from the token)
- `Auth::guard('sanctum')->user()` — explicit guard reference

For passing the user OUT of HTTP context (into an Action, Job, etc.): the controller passes `$request->user()` into the action's `execute(User $user, ...)`.

## Token abilities (optional)

Sanctum supports per-token scopes:

```php
$token = $user->createToken('mobile-app', ['orders:read', 'orders:write']);

Route::middleware(['auth:sanctum', 'ability:orders:write'])->post('/orders', ...);
```
