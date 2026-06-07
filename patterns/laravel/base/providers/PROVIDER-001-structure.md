# PROVIDER-001-structure

## Pattern

Service providers are the central place to register container bindings and run framework
boot-time wiring (view composers, macros, gates, model observers, route model bindings).

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Providers;

use App\Contracts\PaymentGateway;
use App\Services\StripePaymentGateway;
use Illuminate\Support\ServiceProvider;

class PaymentServiceProvider extends ServiceProvider
{
    /**
     * Register container bindings. Runs first, for ALL providers.
     * Only bind things here — never resolve other services (they may not be registered yet).
     */
    public function register(): void
    {
        $this->app->singleton(PaymentGateway::class, StripePaymentGateway::class);
    }

    /**
     * Boot the service. Runs after every provider has registered, so it's safe to
     * resolve dependencies and touch other services here.
     */
    public function boot(): void
    {
        // view composers, macros, gates, observers, route model bindings, etc.
    }
}
```

## register() vs boot()

- **`register()`** — bind into the container only. The container isn't fully populated yet, so
  don't resolve or use other services here.
- **`boot()`** — everything else. By the time `boot()` runs, all providers have registered, so
  you can resolve dependencies and wire framework hooks.

## Binding Styles

```php
// Singleton — one shared instance, reused for the entire life of the app instance
$this->app->singleton(PaymentGateway::class, StripePaymentGateway::class);

// Scoped — one instance per request/job lifecycle; flushed when a long-lived worker
// (Octane, queue) starts the next request/job. Use for per-request shared state.
$this->app->scoped(RequestContext::class, fn ($app) => new RequestContext());

// bind — a fresh instance every time it's resolved
$this->app->bind(ReportBuilder::class, fn ($app) => new ReportBuilder($app->make(Clock::class)));

// instance — bind an already-constructed object
$this->app->instance(Clock::class, new SystemClock());

// Contextual binding — different implementation per consumer
$this->app->when(InvoiceMailer::class)
    ->needs(Transport::class)
    ->give(fn () => new SesTransport());
```

Bind an **interface → implementation** so consumers type-hint the contract and the
implementation can be swapped (tests, drivers) without touching call sites.

## Lifecycle: how the binding method behaves per runtime

The binding method only matters once you know how long the application instance lives, and that
depends on the runtime:

- **PHP-FPM / mod_php (default).** A fresh application boots on **every** request — all
  providers' `register()` + `boot()` run, the request is served, then the whole thing is torn
  down. Nothing survives between requests. Here `singleton` and `scoped` are effectively
  identical: the process dies at the end anyway, so "one instance forever" and "one instance per
  request" collapse to the same thing.
- **Long-lived workers — Octane and queue workers.** The application boots **once** and stays
  resident in memory across many requests/jobs. `register()`/`boot()` run a single time at
  worker startup, **not** per request. This is where the distinction bites:

| Binding | PHP-FPM | Octane / queue worker |
|---------|---------|------------------------|
| `singleton` | one per request (process dies after) | **one for the worker's whole life** — shared across every request/job until the worker restarts |
| `scoped` | one per request | one per request/job — **flushed** when the worker begins the next lifecycle |
| `bind` | fresh per resolve | fresh per resolve |

**Rule of thumb:** if an instance holds **request- or job-specific state** (the current user,
tenant, a request-scoped cache), use `scoped` — never `singleton` — or it will leak into the
next request on a long-lived worker. Use `singleton` only for genuinely stateless services
(an HTTP client, a stateless gateway).

## Octane safety

Under Octane the same container and the same singletons are reused across requests, so a few
patterns that are harmless under FPM become bugs:

- **Never inject the `Request` (or request-derived state) into a `singleton` constructor** — the
  singleton captures the *first* request and serves stale data to every later request. Resolve
  the request inside the method that needs it (`request()`), or make the service `scoped`.
- **Never capture the container into a long-lived object.** A singleton that stores `$app` holds
  a stale container that may be missing bindings added later. Inject a resolver closure
  (`fn () => app()`) and call it on demand, or use `Container::getInstance()` / the `app()`
  helper, which always return the current instance.
- **Watch static/global state.** Static properties, in-memory registries, and `boot()`-time
  mutations accumulate across requests because `boot()` only runs once per worker. Keep
  per-request state in `scoped` bindings, not statics.

These are container-binding concerns and belong here. Octane's *runtime* (installation,
`octane:start`, concurrent tasks, cache/table storage, tick intervals) is operational config,
not a provider concern.

## Deferred Providers

If a provider only registers bindings (no `boot()` side effects), defer it so it loads lazily
when one of its bindings is first resolved:

```php
use Illuminate\Contracts\Support\DeferrableProvider;

class PaymentServiceProvider extends ServiceProvider implements DeferrableProvider
{
    public function register(): void
    {
        $this->app->singleton(PaymentGateway::class, StripePaymentGateway::class);
    }

    /**
     * @return array<int, class-string>
     */
    public function provides(): array
    {
        return [PaymentGateway::class];
    }
}
```

Deferred providers are skipped on every request that doesn't need them. Don't defer a provider
that has a `boot()` method or registers routes/event listeners.

## Registration

Providers are registered in `bootstrap/providers.php`:

```php
return [
    App\Providers\AppServiceProvider::class,
    App\Providers\PaymentServiceProvider::class,
];
```

`php artisan make:provider PaymentServiceProvider` creates the class and appends it to that
array automatically.

## Common boot() responsibilities

```php
public function boot(): void
{
    // Model observers
    Order::observe(OrderObserver::class);

    // Route model binding with custom resolution
    Route::bind('order', fn ($value) => Order::where('reference', $value)->firstOrFail());

    // Macros
    Str::macro('initials', fn (string $name) => collect(explode(' ', $name))
        ->map(fn ($p) => mb_substr($p, 0, 1))
        ->join(''));

    // View composers
    View::composer('dashboard', DashboardComposer::class);
}
```

## Key Points

- Lives in `app/Providers/`; extend `Illuminate\Support\ServiceProvider`
- `register()` binds only; `boot()` does everything that needs other services
- Bind interface → implementation; `singleton()` for **stateless** shared services, `scoped()` for **request/job-scoped** state, `bind()` for fresh-each-resolve
- On long-lived workers (Octane, queue) a `singleton` lives for the whole worker — never put request/job state in one, and never inject `Request`/the container into a singleton constructor (use `scoped`, `request()`, or a `fn () => app()` resolver)
- Use contextual binding (`when()->needs()->give()`) when consumers need different implementations
- Implement `DeferrableProvider` + `provides()` for binding-only providers (no `boot()`, no routes/events)
- Register in `bootstrap/providers.php` (`make:provider` appends automatically)
- Event listeners and policies auto-discover — you rarely need a dedicated Event provider
