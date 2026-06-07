---
overrides: base/http/controllers/CONTROLLER-002-invokable.md
target: laravel-12
reason: Laravel 12 doesn't have controller attributes — wire middleware at route level, authorize inside __invoke (no #[Authorize] attribute).
base-hash: 35a1e6
---

> ⚠️ **Laravel 12 — no controller attributes.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# CONTROLLER-002-invokable

## Pattern

Single-action controllers for standalone endpoints that don't fit into resource CRUD or grouped operations.

**Use when:**
- Endpoint has no related actions (standalone)
- Action doesn't belong to a resource's CRUD
- One-off operations (verify email, export report, health check)

## Structure (Laravel 12 — middleware at route level)

Laravel 12 has no `#[Middleware]` attribute. Attach middleware on the route (or route group) instead. The controller is just the `__invoke()` method.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;

class VerifyEmailController extends Controller
{
    /**
     * Handle the incoming request.
     */
    public function __invoke(
        VerifyEmailRequest $request,
        VerifyEmailAction $action
    ): JsonResponse {
        $action->execute($request->token);

        return response()->json([
            'message' => 'Email verified successfully',
        ]);
    }
}
```

## Authorization on Invokables

For invokables that need policy authorization, attach `->can()` on the route (see the routing pattern) or call `$this->authorize()` inside `__invoke`:

```php
use App\Models\Order;

class MarkOrderShippedController extends Controller
{
    public function __invoke(Order $order, ShipOrderAction $action): JsonResponse
    {
        $this->authorize('ship', $order);

        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order marked shipped',
            'data' => new OrderResource($order),
        ]);
    }
}
```

For invokables that DON'T need authorization (health checks, public webhooks), skip the authorization check entirely.

## Examples

### Standalone Action

```php
class ExportReportController extends Controller
{
    public function __invoke(
        ExportReportRequest $request,
        ExportReportAction $action
    ): StreamedResponse {
        $this->authorize('export', Report::class);

        return $action->execute($request->toDto());
    }
}
```

### Health Check (no middleware, no auth)

```php
class HealthCheckController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return response()->json([
            'status' => 'healthy',
            'timestamp' => now()->toIso8601String(),
        ]);
    }
}
```

### Token-Based Action (rate-limited, no policy)

```php
class ResetPasswordController extends Controller
{
    public function __invoke(
        ResetPasswordRequest $request,
        ResetPasswordAction $action
    ): JsonResponse {
        $action->execute(
            token: $request->token,
            password: $request->password
        );

        return response()->json([
            'message' => 'Password reset successfully',
        ]);
    }
}
```

## Route Registration

Middleware and authorization attach at route level (no controller attributes on L12):

```php
// Single invokable controller — middleware/auth wired on the route
Route::post('/verify-email', VerifyEmailController::class)->middleware('throttle:6,1');
Route::post('/reset-password', ResetPasswordController::class)->middleware('throttle:5,1');
Route::get('/health', HealthCheckController::class);
Route::post('/export/report', ExportReportController::class)->middleware('auth:sanctum');
Route::post('/orders/{order}/mark-shipped', MarkOrderShippedController::class)
    ->middleware('auth:sanctum')
    ->can('ship', 'order');
```

Keep route files focused on URL → controller mapping plus the middleware/authorization the endpoint needs.

## Naming Convention

**Controller name = action + "Controller"**

- `VerifyEmailController` - Handles email verification
- `ResetPasswordController` - Handles password reset
- `ExportReportController` - Handles report export
- `HealthCheckController` - Handles health check
- `MarkOrderShippedController` - Handles a single state-transition action

## When to Use

✅ **Use invokable controllers for:**
- Standalone actions with no related endpoints
- One-off operations
- Webhook handlers
- Health checks
- Export/import endpoints (if standalone)
- Token-based actions (verify, reset, confirm)

❌ **Don't use for:**
- CRUD operations → use a resource controller
- Related actions (accept/deny/cancel) → use a grouped controller
- Actions that belong to a resource

## Key Points

- Single `__invoke()` method only
- Name describes the action (VerifyEmailController, not EmailController)
- Delegate to Action for business logic
- Keep controller thin - HTTP concerns only
- Route points directly to controller class (no method specified)
- **L12: attach middleware on the route via `->middleware('...')`**
- **L12: authorize via `->can('ability', 'param')` on the route, or `$this->authorize()` inside `__invoke`**
