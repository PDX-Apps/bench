# LISTEN-002

## Pattern

Queued event listeners execute asynchronously in background jobs.

## Structure (Laravel 13 — with `#[WithoutRelations]`)

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Listeners;

use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\Attributes\WithoutRelations;
use Modules\{Module}\Events\{EventName};
use Modules\{Module}\Models\{Model};

#[WithoutRelations]
class {ActionDescription} implements ShouldQueue
{
    public function handle({EventName} $event): void
    {
        // Re-fetch model from ID (see EVENT-002)
        $model = {Model}::find($event->modelId);

        if (! $model) {
            // Handle deletion between dispatch and execution
            return;
        }

        // Work with a fresh model
        // Can be slow, can fail independently
    }
}
```

## Why `#[WithoutRelations]`

When a queued event is dispatched, Laravel serializes the event object (including any model properties on it) into the queue store. If the model has eager-loaded relations, those relations are serialized too — bloating payloads and capturing a snapshot of data that may be stale by the time the worker picks the job up.

`#[WithoutRelations]` on the listener strips those relations during serialization. The model stub still carries the primary key; you re-fetch fresh state in `handle()` per the existing EVENT-002 rule (pass IDs, not models).

Combine with the project rule of passing IDs in events: belt-and-suspenders against payload bloat.

### Without the attribute

```php
// Event with a model that has eager-loaded relations:
class OrderShipped
{
    public function __construct(public Order $order) {}
}

// Dispatched after: $order = Order::with('items', 'customer', 'shippingAddress')->find(1);
// Queue payload includes Order + Items + Customer + Address — potentially KB+ of JSON.
```

### With the attribute

```php
#[WithoutRelations]
class SendShipmentNotification implements ShouldQueue
{
    public function handle(OrderShipped $event): void
    {
        // $event->order has no relations loaded — payload is small
        // Re-fetch with the relations you actually need:
        $order = Order::with('items')->find($event->order->id);
        // ...
    }
}
```

## Key Points

- Implements `ShouldQueue`
- Executes asynchronously in queue worker
- Listener failure doesn't affect original request
- See `EVENT-002` for passing IDs instead of models
- Can retry on failure
- **L13: add `#[WithoutRelations]` to strip eager-loaded relations from queue payload** (smaller payloads, no stale-relation surprises)

## Examples

**Good for queued:**
- Send emails
- Call external APIs
- Generate reports
- Process images/files
- Sync to third-party services

**Bad for queued:**
- Critical side effects are needed immediately
- Updates that must happen before response
- Validation that affects a request outcome
