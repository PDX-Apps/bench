---
overrides: base/http/controllers/CONTROLLER-003-grouped.md
target: laravel-12
reason: Laravel 12 doesn't have #[Authorize] on controller methods — authorization lives on routes via ->can().
base-hash: 48e6ea
---

> ⚠️ **Laravel 12 — authorize via route ->can().** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# CONTROLLER-003-grouped

## Pattern

Controllers that group **related non-CRUD operations** (max 4-5 methods). Used for domain operations that don't fit resource CRUD but share a common context.

**Use when:**
- Multiple related actions on the same entity
- State machine operations (accept, deny, cancel)
- Sub-resource operations
- Domain-specific endpoints

## Structure (Laravel 12 — authorize via route `->can()`)

Laravel 12 has no `#[Authorize]` attribute. Authorization lives on the route definition via `->can('ability', 'param')`. The controller methods stay free of authorization wiring; group-wide middleware sits on the route group.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\JsonResponse;

/**
 * Handles order state transitions.
 * Authorization handled via ->can() in route definitions.
 * Max 4-5 related methods. If more needed, split into multiple controllers.
 */
class OrderStateController extends Controller
{
    public function place(Order $order, PlaceOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order placed',
            'data' => new OrderResource($order),
        ]);
    }

    public function cancel(Order $order, CancelOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order cancelled',
            'data' => new OrderResource($order),
        ]);
    }

    public function fulfill(Order $order, FulfillOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order fulfilled',
            'data' => new OrderResource($order),
        ]);
    }
}
```

## Examples

### Membership Controller

```php
/**
 * Handles group membership operations.
 * Authorization handled via ->can() in route definitions.
 */
class MembershipController extends Controller
{
    public function join(Group $group, JoinGroupAction $action): JsonResponse
    {
        $membership = $action->execute($group);
        return response()->json(['message' => 'Joined group', 'data' => new MembershipResource($membership)]);
    }

    public function leave(Group $group, LeaveGroupAction $action): JsonResponse
    {
        $action->execute($group);
        return response()->json(['message' => 'Left group'], 200);
    }

    public function transfer(
        Group $group,
        TransferOwnershipRequest $request,
        TransferOwnershipAction $action
    ): JsonResponse {
        $group = $action->execute($group, $request->new_owner_id);
        return response()->json(['message' => 'Ownership transferred', 'data' => new GroupResource($group)]);
    }
}
```

## Route Registration (L12 — authorize on the route)

With no `#[Authorize]` attribute, each route carries its own `->can()`:

```php
// Order state transitions
Route::post('orders/{order}/place', [OrderStateController::class, 'place'])
    ->name('orders.place')
    ->can('place', 'order');
Route::post('orders/{order}/cancel', [OrderStateController::class, 'cancel'])
    ->name('orders.cancel')
    ->can('cancel', 'order');
Route::post('orders/{order}/fulfill', [OrderStateController::class, 'fulfill'])
    ->name('orders.fulfill')
    ->can('fulfill', 'order');

// Membership operations
Route::post('groups/{group}/join', [MembershipController::class, 'join'])
    ->name('groups.join')
    ->can('join', 'group');
Route::post('groups/{group}/leave', [MembershipController::class, 'leave'])
    ->name('groups.leave')
    ->can('leave', 'group');
Route::post('groups/{group}/transfer', [MembershipController::class, 'transfer'])
    ->name('groups.transfer')
    ->can('transferOwnership', 'group');
```

The `->can('place', 'order')` etc. repeats intent that the latest version co-locates on the method via `#[Authorize]` — but that attribute isn't available on L12, so the route is the home for it.

## Naming Convention

**Controller name = context + operation type + "Controller"**

- `OrderStateController` - Handles order state transitions
- `MembershipController` - Handles join/leave/transfer operations
- `PaymentController` - Handles charge/refund/void operations

## When to Use

✅ **Use grouped controllers for:**
- State machine transitions (accept/deny/cancel, place/cancel/fulfill)
- Related domain operations (join/leave/transfer)
- Sub-resource operations that don't fit CRUD
- Max 4-5 methods - if more, split into multiple controllers

❌ **Don't use for:**
- CRUD operations → use a resource controller
- Standalone actions → use an invokable controller
- More than 5 methods → split into multiple controllers

## Key Points

- **Max 4-5 methods per controller** — keeps controllers focused
- Group by domain concept, not by entity
- Each method handles one operation
- Delegate to Actions for business logic
- **L12: `->can('ability', 'paramName')` on each route** (no `#[Authorize]` attribute)
- **L12: shared middleware on the route group** at class level isn't available
- Descriptive method names (accept, deny, cancel — not action1, action2)
- Keep controllers thin — HTTP concerns only
- POST for state-changing operations (even if no body)

## Choosing the Right Controller Type

| Scenario | Controller Type |
|----------|-----------------|
| Standard CRUD (list, create, read, update, delete) | Resource controller |
| Standalone action (verify email, health check) | Invokable controller |
| Related operations (place/cancel/fulfill) | Grouped controller |
| More than 5 related operations | Split into multiple grouped controllers |
