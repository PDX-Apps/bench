# HTTP-007-middleware

## Pattern

HTTP middleware for cross-cutting request/response concerns (auth checks, throttling, logging, request mutation, response wrapping).

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Audit\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Modules\Audit\Services\JourneyService;
use Symfony\Component\HttpFoundation\Response;

class CompleteJourneyMiddleware
{
    public function __construct(protected JourneyService $journeys) {}

    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        if ($this->journeys->hasActiveJourney()) {
            $this->journeys->complete();
        }

        return $response;
    }
}
```

## Registration (Laravel 12)

Laravel 12 registers middleware in `bootstrap/app.php`, NOT `app/Http/Kernel.php` (which doesn't exist):

```php
// bootstrap/app.php
->withMiddleware(function (Middleware $middleware) {
    $middleware->alias([
        'complete-journey' => \Modules\Audit\Http\Middleware\CompleteJourneyMiddleware::class,
    ]);

    $middleware->appendToGroup('api', [
        \Modules\Audit\Http\Middleware\CompleteJourneyMiddleware::class,
    ]);
})
```

For module-scoped middleware, register in the module's `RouteServiceProvider` or service provider.

## Applying to Routes

Via alias in routes:
```php
Route::post('/bills', [BillController::class, 'store'])
    ->middleware('complete-journey');
```

Via FQCN:
```php
Route::middleware([CompleteJourneyMiddleware::class])->group(function () {
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

## Rules

- Single method: `handle(Request $request, Closure $next): Response`
- Use constructor property promotion for dependencies
- Live in `Modules/{Module}/app/Http/Middleware/`
- Register in `bootstrap/app.php` for global, or module's RouteServiceProvider for scoped
- Use middleware aliases for short, readable route declarations
- Implement `terminate()` for post-response work (logging, cleanup)
- Strict types via `declare(strict_types=1)` recommended
- Avoid heavy synchronous work — defer to Jobs (see JOB-001)

## Key Points

- Single `handle()` method — `$next($request)` calls the next layer
- Laravel 12 registers middleware in `bootstrap/app.php`
- Aliases for clean route declarations
- Use `terminate()` for post-response work
- Module-scoped middleware lives in the module
- See AUTH-002-api for Sanctum middleware (built-in, not custom)
- See HTTP-004-routes for applying middleware to routes
