---
overrides: base/http/controllers/CONTROLLER-003-grouped.md
target: laravel-12
reason: Laravel 12 doesn't have #[Authorize] on controller methods — authorization lives on routes via ->can().
base-hash: e16d5a
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

## Dependencies

- `http/HTTP-001-resource-controllers.md` - Resource controllers (for CRUD)
- `http/HTTP-005-invokable-controllers.md` - Invokable controllers (for standalone actions)
- `http/HTTP-002-form-requests.md` - FormRequests with validation
- `services/SERVICE-001-actions.md` - Actions for business logic
- `models/MODEL-003-domain-methods.md` - Domain methods for state transitions

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Controllers;

use App\Http\Controllers\Controller;use Illuminate\Http\JsonResponse;

/**
 * Handles invitation state transitions.
 *
 * Max 4-5 related methods. If more needed, split into multiple controllers.
 */
class InvitationResponseController extends Controller
{
    /**
     * Accept an invitation.
     */
    public function accept(
        Invitation $invitation,
        AcceptInvitationAction $action
    ): JsonResponse {
        // Authorization handled via ->can() in route definition
        $invitation = $action->execute($invitation);

        return response()->json([
            'message' => 'Invitation accepted',
            'data' => new InvitationResource($invitation),
        ]);
    }

    /**
     * Deny an invitation.
     */
    public function deny(
        Invitation $invitation,
        DenyInvitationAction $action
    ): JsonResponse {
        $invitation = $action->execute($invitation);

        return response()->json([
            'message' => 'Invitation denied',
            'data' => new InvitationResource($invitation),
        ]);
    }

    /**
     * Cancel an invitation (by inviter).
     */
    public function cancel(
        Invitation $invitation,
        CancelInvitationAction $action
    ): JsonResponse {
        $invitation = $action->execute($invitation);

        return response()->json([
            'message' => 'Invitation cancelled',
            'data' => new InvitationResource($invitation),
        ]);
    }
}
```

## Examples

### State Machine Controller

```php
/**
 * Handles order state transitions.
 * Authorization handled via ->can() in route definitions.
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

        return response()->json([
            'message' => 'Joined group',
            'data' => new MembershipResource($membership),
        ]);
    }

    public function leave(Group $group, LeaveGroupAction $action): JsonResponse
    {
        $action->execute($group);

        return response()->json([
            'message' => 'Left group',
        ], 200);
    }

    public function transfer(
        Group $group,
        TransferOwnershipRequest $request,
        TransferOwnershipAction $action
    ): JsonResponse {
        $group = $action->execute($group, $request->new_owner_id);

        return response()->json([
            'message' => 'Ownership transferred',
            'data' => new GroupResource($group),
        ]);
    }
}
```

## Route Registration

Authorization is defined at the route level with `->can()`. See `HTTP-004-routes` and `POLICY-002-action-policies`.

```php
// Invitation state transitions
Route::post('invitations/{invitation}/accept', [InvitationResponseController::class, 'accept'])
    ->name('invitations.accept')
    ->can('accept', 'invitation');

Route::post('invitations/{invitation}/deny', [InvitationResponseController::class, 'deny'])
    ->name('invitations.deny')
    ->can('deny', 'invitation');

Route::post('invitations/{invitation}/cancel', [InvitationResponseController::class, 'cancel'])
    ->name('invitations.cancel')
    ->can('cancel', 'invitation');

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

## Naming Convention

**Controller name = context + operation type + "Controller"**

- `InvitationResponseController` - Handles invitation accept/deny/cancel
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
- CRUD operations → Use `HTTP-001-resource-controllers`
- Standalone actions → Use `HTTP-005-invokable-controllers`
- More than 5 methods → Split into multiple controllers

## Key Points

- **Max 4-5 methods per controller** - keeps controllers focused
- Group by domain concept, not by entity
- Each method handles one operation
- Delegate to Actions for business logic
- Authorization via `->can()` on routes (see `POLICY-002-action-policies`)
- Descriptive method names (accept, deny, cancel - not action1, action2)
- Keep controllers thin - HTTP concerns only
- POST for state-changing operations (even if no body)

## Choosing the Right Controller Type

| Scenario | Controller Type |
|----------|-----------------|
| Standard CRUD (list, create, read, update, delete) | `HTTP-001-resource-controllers` |
| Standalone action (verify email, health check) | `HTTP-005-invokable-controllers` |
| Related operations (accept/deny/cancel) | `HTTP-006-grouped-controllers` |
| More than 5 related operations | Split into multiple grouped controllers |

## Related

- `HTTP-001-resource-controllers` - CRUD operations
- `HTTP-005-invokable-controllers` - Standalone actions
- `SERVICE-001-actions` - Business logic
- `MODEL-003-domain-methods` - Domain methods for state transitions
