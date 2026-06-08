# OCTANE-001-safety

## Pattern

Under Octane the worker boots the application **once** and reuses it for many requests
(FrankenPHP / Swoole / RoadRunner). The container, singletons, static properties, and any
object you keep a reference to all survive between requests. Write request-handling code
that holds **no per-request state** beyond the request it is handling, and that does not
grow memory over the worker's lifetime.

## Why

In PHP-FPM each request gets a fresh process, so leaked state and slow leaks are wiped on
every request. Octane removes that safety net:

- A value captured during boot (the first request) is silently reused for **every** later
  request — leading to data bleeding between users.
- Anything appended to a `static` array or a singleton's property accumulates for the life
  of the worker — a slow memory leak that eventually OOMs the worker.

## Do NOT do this

```php
<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Http\Request;

final class OrderContext
{
    /** @var array<int, string> grows forever across requests — memory leak */
    private static array $seen = [];

    // Captured once at construction; if this is a singleton it freezes on
    // the FIRST request's Request and returns stale data thereafter.
    public function __construct(private readonly Request $request) {}

    public function remember(int $orderId): void
    {
        self::$seen[] = $this->request->ip(); // unbounded static growth
    }
}
```

Registering that as a `singleton` makes both problems live:

```php
// AppServiceProvider::register() — WRONG under Octane
$this->app->singleton(OrderContext::class); // captures request 1 forever
```

## Octane-safe alternatives

### 1. Use `scoped`, not `singleton`, for anything holding request state

`scoped` bindings are flushed and re-resolved at the start of each request, so they never
carry one request's data into the next.

```php
// AppServiceProvider::register()
$this->app->scoped(OrderContext::class); // fresh per request
```

### 2. Never capture `Request` (or `auth`/`session`) at construction

Inject the current `Request` into the **method**, or resolve it with the `request()` helper
inside the method — both always reflect the request being handled.

```php
<?php

declare(strict_types=1);

namespace App\Services;

use Illuminate\Http\Request;

final class OrderContext
{
    // No request stored on the instance.
    public function currentIp(Request $request): string
    {
        return $request->ip();
    }
}
```

### 3. Keep static/long-lived state bounded — or don't use it

Static caches and singleton properties must not grow per request. If you need a cache,
prefer the framework cache (`Cache::`), or clear the structure when you're done with it.
Anything you stash on a long-lived object is shared by every subsequent request on that
worker.

### 4. Flush stateful third-party services between requests

If a package keeps internal state across requests, list it under `flush` in
`config/octane.php` so the container resolves it fresh each request:

```php
// config/octane.php
'flush' => [
    'some-stateful-service',
],
```

For services that hold request-specific state but you can't make `scoped`, add a reset
listener on `RequestReceived` / `RequestTerminated` to clear it.

### 5. `tick` / `concurrently` callbacks run in the worker, not a fresh process

Closures passed to `Octane::tick(...)` or `Octane::concurrently([...])` execute inside the
long-lived worker. Don't let them capture or mutate request-scoped state, and keep any state
they touch bounded.

```php
use Laravel\Octane\Facades\Octane;

Octane::tick('cleanup', function (): void {
    // periodic, worker-scoped work — no per-request state here
}, seconds: 30, immediate: true);
```

## Checklist before shipping to Octane

- Singletons that touch `Request`/`auth`/`session`/per-user data → make them `scoped`, or
  inject the request per method.
- No `Request`, `auth`, `session`, or current-user captured in a constructor of a
  long-lived binding.
- No `static` array/collection that grows per request; no unbounded growth on singleton
  properties.
- Stateful third-party services listed under `config/octane.php` `flush` (or reset on a
  request listener).
- `tick`/`concurrently` callbacks hold no request state and leak no memory.

## Related

- `<PLUGIN_ROOT>/patterns-built/laravel/providers/PROVIDER-001-structure.md` — where
  container bindings are registered; choose `scoped` vs `singleton` here.
- `<PLUGIN_ROOT>/patterns-built/laravel/services/SERVICE-002-domain-services.md` — services
  are the most common place per-request state leaks in.
