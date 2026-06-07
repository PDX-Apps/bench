# CONTROLLER-003-grouped

## Pattern

Controllers that group **related non-CRUD operations** (max 4-5 methods). Used for domain operations that don't fit resource CRUD but share a common context.

**Use when:**
- Multiple related actions on the same entity
- State machine operations (accept, deny, cancel)
- Sub-resource operations
- Domain-specific endpoints

## Structure (Laravel 13 — `#[Authorize]` per method)

The major shift from L12: authorization moves from `->can()` calls scattered across the route file to `#[Authorize]` attributes sitting on each controller method. The policy ability is co-located with the method that calls into it — easier to read, easier to refactor, easier for static analysis.

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Order;
use Illuminate\Http\JsonResponse;
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Illuminate\Routing\Attributes\Controllers\Middleware;

/**
 * Handles order state transitions.
 * Max 4-5 related methods. If more needed, split into multiple controllers.
 */
#[Middleware('auth:sanctum')]
class OrderStateController extends Controller
{
    #[Authorize('place', 'order')]
    public function place(Order $order, PlaceOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order placed',
            'data' => new OrderResource($order),
        ]);
    }

    #[Authorize('cancel', 'order')]
    public function cancel(Order $order, CancelOrderAction $action): JsonResponse
    {
        $order = $action->execute($order);

        return response()->json([
            'message' => 'Order cancelled',
            'data' => new OrderResource($order),
        ]);
    }

    #[Authorize('fulfill', 'order')]
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
#[Middleware('auth:sanctum')]
class MembershipController extends Controller
{
    #[Authorize('join', 'group')]
    public function join(Group $group, JoinGroupAction $action): JsonResponse
    {
        $membership = $action->execute($group);
        return response()->json(['message' => 'Joined group', 'data' => new MembershipResource($membership)]);
    }

    #[Authorize('leave', 'group')]
    public function leave(Group $group, LeaveGroupAction $action): JsonResponse
    {
        $action->execute($group);
        return response()->json(['message' => 'Left group'], 200);
    }

    #[Authorize('transferOwnership', 'group')]
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

## Route Registration (L13 — simpler)

With `#[Authorize]` on methods, routes drop the `->can()` calls entirely:

```php
// Order state transitions
Route::post('orders/{order}/place', [OrderStateController::class, 'place'])->name('orders.place');
Route::post('orders/{order}/cancel', [OrderStateController::class, 'cancel'])->name('orders.cancel');
Route::post('orders/{order}/fulfill', [OrderStateController::class, 'fulfill'])->name('orders.fulfill');

// Membership operations
Route::post('groups/{group}/join', [MembershipController::class, 'join'])->name('groups.join');
Route::post('groups/{group}/leave', [MembershipController::class, 'leave'])->name('groups.leave');
Route::post('groups/{group}/transfer', [MembershipController::class, 'transfer'])->name('groups.transfer');
```

For comparison, the L12 form had to repeat `->can('place', 'order')` etc. on every route — duplicating intent that's already in the controller method.

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
- **L13: `#[Authorize('ability', 'paramName')]` on each method** (replaces `->can()` on routes)
- **L13: `#[Middleware('...')]` at class level** for shared middleware
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
