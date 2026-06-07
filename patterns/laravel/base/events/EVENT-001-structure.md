# EVENT-001-structure

## Pattern

Events are emitted when something important happens in the domain. An event announces the fact; the code that reacts to it is a separate listener.

## Structure

Default payload is **IDs**, re-fetched by the consumer for fresh state:

```php
<?php

declare(strict_types=1);

namespace App\Events;

use Illuminate\Queue\SerializesModels;

class OrderPlaced
{
    use SerializesModels;

    public function __construct(
        public int $orderId,
        public ?array $metadata = null,
    ) {
    }
}
```

`SerializesModels` only does work when the payload actually contains a model — harmless to keep, and required the moment you pass one. Use `public` properties when the event will be queued (they must serialize); `private` is fine for sync-only events. Keep optional `metadata` to arrays/primitives.

## Payload: IDs vs. models

**Default to IDs, re-fetched in the consumer.** Passing a full model to a *queued* event causes:

- **Serialization issues** — complex relationships, circular references
- **Job-size errors** — SQS caps payloads at 256 KB; Redis has memory limits
- **Race conditions** — model state can change between dispatch and handling
- **Stale data** — the consumer receives an outdated snapshot it didn't ask for

**Pass a model or snapshot when:**
- All consumers are synchronous — no serialization round-trip, so a model is fine
- You deliberately want a **point-in-time snapshot**: the consumer should see the data as it was when the event fired, not a re-fetched current state (e.g. a receipt/confirmation email). Queue-size + serialization limits still apply — for heavy relations, capture just the needed fields in a small DTO rather than passing the whole model.

```php
// Default — IDs for queued consumers, re-fetch in the consumer
event(new OrderPlaced(orderId: $order->id, metadata: ['placed_by' => $user->id]));

// Avoid — queued event carrying a full model (serialization + staleness)
event(new OrderPlaced(order: $order)); // relationships; goes stale before the consumer runs

// OK — sync event can pass a model (no ShouldQueue consumers)
event(new OrderValidated($order));

// OK — deliberate snapshot: a small DTO of just the fields the receipt needs
event(new OrderReceiptIssued(OrderReceiptData::fromOrder($order)));
```

> This applies to the custom events you create — not Laravel's built-in model events (`created`, `updated`, …), which pass models and are synchronous by default.

## Dispatch Strategies

### Manual Dispatch (Recommended)

Dispatch events explicitly where the business action completes — typically in an Action:

```php
// In PlaceOrderAction
$order = Order::create([...]);
event(new OrderPlaced($order->id));
return $order;
```

Use when events should only fire through the business-logic layer, the event needs custom data, you want to prevent accidental firing in tests/seeders, or you want full control over when events fire.

### Automatic Dispatch (Alternative)

Map model lifecycle events to custom events with `$dispatchesEvents`:

```php
class Order extends Model
{
    protected $dispatchesEvents = [
        'created' => OrderCreated::class,
        'updated' => OrderUpdated::class,
        'deleted' => OrderDeleted::class,
    ];
}
```

Use for simple CRUD where the event always needs to fire and only needs the model. Trade-offs: events fire everywhere (tests, seeders, console), the data can't be customized beyond the model, and the coupling is less explicit.

## Naming

Descriptive of what happened, is happening, or will happen:

- **Past tense (already happened):** `OrderPlaced`, `SubscriptionCancelled`, `PaymentCaptured`
- **Future / scheduled:** `ReminderWillSend`, `SubscriptionWillRenew`
- **State detection:** `LowStockDetected`, `QuotaExceeded`

## Key Points

- Default payload is IDs; re-fetch in the consumer (pass a model/snapshot only deliberately — see above)
- `public` properties when the event will be queued; `private` fine for sync-only
- Dispatch with the `event(new EventName($data))` helper
- Default approach: manual dispatch where the business action completes (typically an Action)
- Handle the case where a re-fetched record was deleted before the consumer ran
