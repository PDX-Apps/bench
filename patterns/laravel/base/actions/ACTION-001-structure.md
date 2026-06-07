# ACTION-001-structure

## Pattern

Single-purpose business operations. One Action, one responsibility. One public `execute()` method.

## Auth handling

Actions take `User $user` as the **first parameter** of `execute()` when they need the current user. Caller supplies it. Keeps the action callable from any context.

## Structure

Actions orchestrate domain operations — models own their state, Actions handle persistence and side effects.

```php
<?php

declare(strict_types=1);

namespace App\Actions;

use App\Data\OrderData;
use App\Events\OrderPlaced;
use App\Models\Order;
use App\Models\User;
use App\Repositories\OrderRepository;

class PlaceOrderAction
{
    public function __construct(
        private readonly OrderRepository $orders,
    ) {}

    public function execute(User $user, OrderData $data): Order
    {
        // Model enforces business rules and state transition
        $order = $this->orders->draftFor($user, $data);
        $order->place();

        // Action handles persistence
        $order->save();

        // Action handles side effects (events)
        event(new OrderPlaced(
            orderId: $order->id,
            userId: $user->id,
        ));

        return $order->fresh();
    }
}
```

**Pattern shape:**
- Caller passes `User $user` (the current user is the caller's concern, not the action's)
- Model method handles state transition: `$order->place()`
- Action handles save: `$order->save()`
- Action handles events: `event(new OrderPlaced(...))`

## Models vs Actions: division of responsibilities

**Models handle:**
- ✅ State transitions (`place()`, `cancel()`, `activate()`)
- ✅ Business rule enforcement (can't place an already-placed order)
- ✅ Invariant protection (state consistency)
- ✅ Domain queries (`isDraft()`, `isOwner()`)
- ✅ Derived calculations (`getRemainingBalance()`)

**Actions handle:**
- ✅ Persistence (`save()`)
- ✅ Event dispatching (`event(...)`)
- ✅ Coordinating multiple models
- ✅ External service calls
- ✅ Complex validation across entities
- ✅ Transaction management

## Actions calling other Actions

```php
class PlaceOrderWithItemsAction
{
    public function __construct(
        private readonly PlaceOrderAction $placeOrder,
        private readonly AddOrderItemAction $addItem,
    ) {}

    public function execute(User $user, OrderData $orderData, array $itemData): Order
    {
        $order = $this->placeOrder->execute($user, $orderData);

        foreach ($itemData as $item) {
            $this->addItem->execute($user, $order, $item);
        }

        return $order;
    }
}
```

## When to use Actions

**Use Actions for:**
- Complex business operations
- Operations reused across controllers/jobs/commands
- When you want strong single-responsibility

## Gotchas

A couple of situational things to watch for:

- **Calling the Action from a job or console command?** Be careful what you inject in the constructor. `Request`, `Session`, auth-context services etc. aren't available outside an HTTP request — pass the data you need into `execute()` instead.
- **Binding the Action as a singleton in Octane?** Avoid capturing per-request state (`Request`, current user, etc.) in the constructor — it'll go stale across requests. Default (transient) binding doesn't have this issue.
