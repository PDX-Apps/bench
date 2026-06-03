# HTTP-005-invokable-controllers

## Pattern

Single-action controllers for standalone endpoints that don't fit into resource CRUD or grouped operations.

**Use when:**
- Endpoint has no related actions (standalone)
- Action doesn't belong to a resource's CRUD
- One-off operations (verify email, export report, health check)

## Dependencies

- `http/HTTP-001-resource-controllers.md` - Resource controllers (for CRUD)
- `http/HTTP-006-grouped-controllers.md` - Grouped controllers (for related non-CRUD)
- `http/HTTP-002-form-requests.md` - FormRequests with validation
- `services/SERVICE-001-actions.md` - Actions for business logic

## Structure (Laravel 13 — with attributes)

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Controllers;

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
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Modules\Bill\Models\Bill;

#[Middleware('auth:sanctum')]
class MarkBillPaidController extends Controller
{
    #[Authorize('markPaid', 'bill')]
    public function __invoke(Bill $bill, MarkBillPaidAction $action): JsonResponse
    {
        $bill = $action->execute($bill);

        return response()->json([
            'message' => 'Bill marked paid',
            'data' => new BillResource($bill),
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
        return $action->execute($request->toData());
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
Route::post('/bills/{bill}/mark-paid', MarkBillPaidController::class);
```

Middleware no longer needs to be attached at route level when declared on the controller — keeps route files focused on URL → controller mapping.

## Naming Convention

**Controller name = action + "Controller"**

- `VerifyEmailController` - Handles email verification
- `ResetPasswordController` - Handles password reset
- `ExportReportController` - Handles report export
- `HealthCheckController` - Handles health check
- `MarkBillPaidController` - Handles a single state-transition action

## When to Use

✅ **Use invokable controllers for:**
- Standalone actions with no related endpoints
- One-off operations
- Webhook handlers
- Health checks
- Export/import endpoints (if standalone)
- Token-based actions (verify, reset, confirm)

❌ **Don't use for:**
- CRUD operations → Use `HTTP-001-resource-controllers`
- Related actions (accept/deny/cancel) → Use `HTTP-006-grouped-controllers`
- Actions that belong to a resource

## Key Points

- Single `__invoke()` method only
- Name describes the action (VerifyEmailController, not EmailController)
- Delegate to Action for business logic
- Keep controller thin - HTTP concerns only
- Route points directly to controller class (no method specified)
- **L13: use `#[Middleware('...')]` on the class for shared middleware**
- **L13: use `#[Authorize('ability', 'param')]` on `__invoke` for policy authorization**

## Related

- `HTTP-001-resource-controllers` - CRUD operations
- `HTTP-006-grouped-controllers` - Related non-CRUD operations
- `SERVICE-001-actions` - Business logic
