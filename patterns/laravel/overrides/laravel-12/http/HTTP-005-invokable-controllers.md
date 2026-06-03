---
overrides: base/http/HTTP-005-invokable-controllers.md
target: laravel-12
reason: Laravel 12 doesn't have controller attributes — wire middleware at route level, no #[Authorize] on __invoke.
base-hash: 245d09
---

> ⚠️ **Laravel 12 — no controller attributes.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

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

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Controllers;

use App\Http\Controllers\Controller;use Illuminate\Http\JsonResponse;

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

## Examples

### Standalone Action

```php
class ExportReportController extends Controller
{
    public function __invoke(
        ExportReportRequest $request,
        ExportReportAction $action
    ): StreamedResponse {
        return $action->execute($request->toData());
    }
}
```

### Health Check

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

### Token-Based Action

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

```php
// Single invokable controller
Route::post('/verify-email', VerifyEmailController::class);
Route::post('/reset-password', ResetPasswordController::class);
Route::get('/health', HealthCheckController::class);
Route::post('/export/report', ExportReportController::class);
```

## Naming Convention

**Controller name = action + "Controller"**

- `VerifyEmailController` - Handles email verification
- `ResetPasswordController` - Handles password reset
- `ExportReportController` - Handles report export
- `HealthCheckController` - Handles health check

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

## Related

- `HTTP-001-resource-controllers` - CRUD operations
- `HTTP-006-grouped-controllers` - Related non-CRUD operations
- `SERVICE-001-actions` - Business logic
