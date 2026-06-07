# MIDDLEWARE-001

## Pattern

HTTP middleware for cross-cutting request/response concerns (auth checks, throttling, logging, request mutation, response wrapping).

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Support\RequestMetrics;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class RecordRequestMetricsMiddleware
{
    public function __construct(protected RequestMetrics $metrics) {}

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        $this->metrics->record($request->path(), $response->getStatusCode());

        return $response;
    }
}
```

## Registration (Laravel 13)

Laravel registers middleware in `bootstrap/app.php`, NOT `app/Http/Kernel.php` (which doesn't exist):

```php
// bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'record-metrics' => \App\Http\Middleware\RecordRequestMetricsMiddleware::class,
    ]);

    $middleware->appendToGroup('api', [
        \App\Http\Middleware\RecordRequestMetricsMiddleware::class,
    ]);
})
```

## Applying to Routes

Via alias in routes:
```php
Route::post('/orders', [OrderController::class, 'store'])
    ->middleware('record-metrics');
```

Via FQCN:
```php
Route::middleware([RecordRequestMetricsMiddleware::class])->group(function () {
    // ...
});
```

## Before/After/Terminating Logic

```php
public function handle(Request $request, Closure $next): Response
{
    // BEFORE: runs before the request reaches the controller
    if (!$request->user()) {
        abort(401);
    }

    $response = $next($request);

    // AFTER: runs after the controller returns the response
    $response->headers->set('X-Custom', 'value');

    return $response;
}

// TERMINATING: runs after response sent to browser (heavy work, logging)
public function terminate(Request $request, Response $response): void
{
    Log::info('Request completed', ['path' => $request->path()]);
}
```

## Key Points

- Live in `app/Http/Middleware/`; single `handle(Request $request, Closure $next): Response` method — `$next($request)` calls the next layer
- Constructor property promotion for dependencies
- Register in `bootstrap/app.php` (alias + group); use aliases for clean route declarations
- Implement `terminate()` for post-response work (logging, cleanup)
- Avoid heavy synchronous work — defer it to a queued Job
- `declare(strict_types=1)` recommended
- Sanctum auth is built-in middleware (not custom) — don't reimplement it
