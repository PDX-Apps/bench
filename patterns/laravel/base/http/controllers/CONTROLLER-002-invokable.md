# CONTROLLER-002-invokable

## Pattern

Single-action controllers for standalone endpoints that don't fit into resource CRUD or grouped operations.

**Use when:**
- Endpoint has no related actions (standalone)
- Action doesn't belong to a resource's CRUD
- One-off operations (verify email, export report, health check)

## Structure (Laravel 13 — with attributes)

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Attributes\Controllers\Middleware;

#[Middleware('throttle:6,1')]   // rate limit invokable endpoints sensibly
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

For invokables that need policy authorization, use `#[Authorize]`:

```php
use App\Models\Order;
use Illuminate\Routing\Attributes\Controllers\Authorize;

#[Middleware('auth:sanctum')]
class MarkOrderShippedController extends Controller
{
    #[Authorize('ship', 'order')]
    public function __invoke(Order $order, ShipOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order marked shipped',
            'data' => new OrderResource($order),
        ]);
    }
}
```

For invokables that DON'T need authorization (health checks, public webhooks), skip the `#[Authorize]` attribute entirely.

## Examples

### Standalone Action

```php
#[Middleware('auth:sanctum')]
class ExportReportController extends Controller
{
    #[Authorize('export', Report::class)]
    public function __invoke(
        ExportReportRequest $request,
        ExportReportAction $action
    ): StreamedResponse {
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
#[Middleware('throttle:5,1')]
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

```php
// Single invokable controller — attributes handle middleware/auth, route just registers
Route::post('/verify-email', VerifyEmailController::class);
Route::post('/reset-password', ResetPasswordController::class);
Route::get('/health', HealthCheckController::class);
Route::post('/export/report', ExportReportController::class);
Route::post('/orders/{order}/mark-shipped', MarkOrderShippedController::class);
```

Middleware no longer needs to be attached at route level when declared on the controller — keeps route files focused on URL → controller mapping.

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
- **L13: use `#[Middleware('...')]` on the class for shared middleware**
- **L13: use `#[Authorize('ability', 'param')]` on `__invoke` for policy authorization**
