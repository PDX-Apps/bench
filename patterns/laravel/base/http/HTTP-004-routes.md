# HTTP-004-routes

## Pattern

Route definitions with middleware, authorization, and naming conventions.

## Route Files

**Use `api.php` only.** Do not create separate `web.php` route files for modules.

Sanctum handles both session (web) and token (mobile) authentication transparently:
- Web/SSR/SPA: Session cookies (automatic via Sanctum)
- Mobile (Capacitor): Bearer tokens (for offline mode, biometric login, etc.)

```php
// Modules/{Module}/routes/api.php
Route::middleware(['auth:sanctum'])->prefix('v1')->group(function () {
    Route::apiResource('households', HouseholdController::class);
});
```

All builds (SSR, SPA, Capacitor) hit the same `/api/v1/` endpoints.

## API Resource Routes

```php
use Modules\{Module}\Http\Controllers\{Model}Controller;

Route::apiResource('{models}', {Model}Controller::class);
```

Laravel automatically generates route names in the format `{models}.index`, `{models}.store`, etc.

## Authorization

**Define authorization in `api.php`, not controllers.** This keeps permissions visible in one place.

For single routes, use `->can()`:

```php
Route::post('households/join', [HouseholdMembershipController::class, 'join'])
    ->name('households.join')
    ->can('join', Household::class);

Route::post('households/{household}/invitations', [HouseholdInvitationController::class, 'store'])
    ->name('household.invitations.store')
    ->can('invite', 'household');

Route::post('invitations/{invitation}/accept', [InvitationResponseController::class, 'accept'])
    ->name('invitations.accept')
    ->can('accept', 'invitation');
```

For resource controllers, use `$this->authorizeResource()` in the constructor (`apiResource()` doesn't support `->can()`):

```php
// api.php
Route::apiResource('households', HouseholdController::class);

// HouseholdController.php
public function __construct()
{
    $this->authorizeResource(Household::class, 'household');
}

// Automatic policy mapping:
// index  -> viewAny
// show   -> view
// store  -> create
// update -> update
// destroy -> delete
```

## Key Points

- Use `api.php` only - no `web.php` for modules
- Use `->middleware('auth:sanctum')` for authenticated routes
- Use `->can()` in route definitions for single routes (keeps authorization visible)
- Use `$this->authorizeResource()` only for resource controllers (no `->can()` on `apiResource()`)
- Use `apiResource()` for standard CRUD routes
- Laravel auto-generates route names for `apiResource()` (no need for `->names()`)
