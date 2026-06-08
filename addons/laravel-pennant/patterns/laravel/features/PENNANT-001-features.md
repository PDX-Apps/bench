# PENNANT-001-features — Feature Flags (Laravel Pennant)

How to define, check, and manage feature flags with `laravel/pennant`:
class-based and closure features, per-user/team scopes, rich values,
Blade directives, route middleware, and lifecycle management.

## Install

```bash
composer require laravel/pennant
php artisan vendor:publish --tag="pennant-migrations"
php artisan migrate
```

The DB driver stores resolved values in a `features` table. The `array` driver
(in-memory, per-request) is also available — set `PENNANT_STORE` in `.env`.

## Defining Features

### Class-based (recommended for non-trivial logic)

Create a feature class anywhere discoverable (e.g. `app/Features/`). Pennant
auto-discovers classes in `app/Features` when using the default service
provider — or register them manually in `AppServiceProvider`.

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;

final class NewCheckout
{
    /**
     * Resolve whether the feature is active for the given scope.
     */
    public function resolve(User $user): bool
    {
        return $user->subscription?->onPlan('pro') ?? false;
    }
}
```

Another example — a gradual rollout by percentage:

```php
<?php

declare(strict_types=1);

namespace App\Features;

use App\Models\User;

final class InvoicePdfV2
{
    public function resolve(User $user): bool
    {
        return $user->id % 10 < 3; // 30 % rollout
    }
}
```

### Closure-based (simple / one-off flags)

Register in a service provider's `boot()` for lightweight flags that don't
warrant a dedicated class:

```php
use Laravel\Pennant\Feature;
use App\Models\User;

Feature::define('seasonal-banner', fn (User $user): bool => now()->month === 12);
```

### Rich-value features

Features can return non-boolean values. `Feature::active()` treats any
non-`false` return as active; `Feature::value()` returns the raw resolved value.

```php
Feature::define('purchase-button', fn (User $user): string => match (true) {
    $user->isVip()  => 'gold-sticky',
    default         => 'blue-sticky',
});
```

## Checking Features

### Boolean checks

```php
use Laravel\Pennant\Feature;

// Active for the default scope (authenticated user)
if (Feature::active('new-checkout')) {
    // ...
}

if (Feature::inactive('new-checkout')) {
    // show legacy checkout
}

// Branching helper — avoids nested if/else
Feature::when(
    'new-checkout',
    fn () => redirect()->route('checkout.new'),
    fn () => redirect()->route('checkout.legacy'),
);
```

### Explicit scope

Pass any model — `User`, `Team`, or any other — as the scope:

```php
// Check for a specific team, not the authenticated user
Feature::for($team)->active('invoice-pdf-v2');

// Check against a different user
Feature::for($order->customer)->active('new-checkout');
```

### Rich-value retrieval

```php
$variant = Feature::value('purchase-button'); // 'blue-sticky' | 'gold-sticky'
```

### Null / global scope

Pass `null` to check a flag that is not scoped to any model (e.g. a
maintenance-mode toggle):

```php
Feature::for(null)->active('maintenance-mode');
```

## Scope

The **default scope** is the currently authenticated user. Pennant resolves it
automatically when you call `Feature::active()` without `->for(...)`.

Override the default scope application-wide in `AppServiceProvider`:

```php
use Laravel\Pennant\Feature;

Feature::resolveScopeUsing(fn ($driver) => request()->user()?->team);
```

This makes every `Feature::active(...)` call evaluate against the current
team unless overridden with `->for(...)`.

## Blade Directive

```blade
@feature('new-checkout')
    <x-checkout-new />
@else
    <x-checkout-legacy />
@endfeature
```

Works with the default scope (authenticated user). For an explicit scope, check
in the controller and pass a boolean to the view instead.

## Route Middleware

Protect routes so they are only accessible when a feature is active for the
current scope:

```php
use Illuminate\Support\Facades\Route;

Route::get('/checkout/new', NewCheckoutController::class)
    ->middleware('features:new-checkout');

// Require multiple flags (all must be active)
Route::get('/invoice/pdf', InvoicePdfController::class)
    ->middleware('features:invoice-pdf-v2,new-checkout');
```

When the feature is inactive the middleware returns a `400` response by
default. Customise the response in `AppServiceProvider`:

```php
use Laravel\Pennant\Middleware\EnsureFeaturesAreActive;

EnsureFeaturesAreActive::whenInactive(
    fn ($request, $features) => redirect()->route('home'),
);
```

## Eager Loading (avoid N+1)

When iterating a collection, load feature values up front:

```php
Feature::load(['new-checkout', 'invoice-pdf-v2']);

// Or load for a specific set of scopes
Feature::loadForEveryone(['new-checkout']);

foreach ($orders as $order) {
    Feature::for($order->customer)->active('new-checkout'); // no extra query
}
```

## Activating / Deactivating Manually

Override the resolved value for a scope — useful for admin panels or tests:

```php
// Force-on for a user
Feature::activate('new-checkout', scope: $user);

// Force-off
Feature::deactivate('new-checkout', scope: $user);

// Restore to the resolved default
Feature::forget('new-checkout', scope: $user);
```

## Lifecycle & Cleanup

Once a feature ships to everyone, remove the flag:

1. Delete the class (or closure registration).
2. Purge stored values: `php artisan pennant:purge new-checkout`.
3. Remove all `Feature::active('new-checkout')` call sites.

Leaving dead flags in the codebase adds confusion and slows down feature
resolution.

## Anti-Patterns

- **Raw `env()` / `config()` checks** — use a defined feature instead; Pennant
  gives you persistence, scoping, and override capability for free.
- **Wrong scope** — checking `Feature::active(...)` (user scope) when the flag
  should be scoped to a team, or vice versa. Be explicit with `->for(...)`.
- **Dead flags** — purge and remove feature flags once they have fully shipped;
  stale flags accumulate in the DB and clutter the codebase.
- **Logic in call sites** — move complex eligibility logic into a class-based
  feature's `resolve()` method, not scattered across controllers and views.

## Key Points

- Class-based features live in `app/Features/`; closure-based flags are
  registered in a service provider's `boot()`.
- The default scope is the authenticated user; override with `->for($scope)`.
- `Feature::active()` treats any non-`false` return as active; use
  `Feature::value()` to get the raw resolved value.
- Values are persisted by the DB driver — `Feature::activate/deactivate` lets
  you override per scope without code changes.
- Eager-load with `Feature::load([...])` before iterating large collections.
- `@feature` / `@endfeature` in Blade; `->middleware('features:flag-name')` on
  routes.
- Purge and delete flags once they ship: `php artisan pennant:purge flag-name`.
