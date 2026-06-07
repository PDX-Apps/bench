---
overrides: base/listeners/LISTEN-002-queued-listeners.md
target: laravel-12
reason: Laravel 12 doesn't have #[WithoutRelations] for listeners — payloads include all eager-loaded relations on the event. Rely on the existing rule of passing IDs in events (not models) to keep payloads small.
base-hash: d538cf
---

> ⚠️ **Laravel 12 — no #[WithoutRelations] attribute.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# LISTEN-002-queued-listeners

## Pattern

Queued event listeners execute asynchronously in background jobs.

## Structure (Laravel 12 — pass IDs in events)

L12 has no `#[WithoutRelations]` attribute to strip eager-loaded relations from the queue payload. Instead, rely on the rule of passing IDs (not models) in events, and re-fetch fresh state in `handle()`.

```php
<?php

declare(strict_types=1);

namespace App\Listeners;

use App\Events\{EventName};
use App\Models\{Model};
use Illuminate\Contracts\Queue\ShouldQueue;

class {ActionDescription} implements ShouldQueue
{
    public function handle({EventName} $event): void
    {
        // Re-fetch model from the ID carried on the event
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

## Why pass IDs, not models

When a queued event is dispatched, Laravel serializes the event object (including any model properties on it) into the queue store. If the model has eager-loaded relations, those relations are serialized too — bloating payloads and capturing a snapshot of data that may be stale by the time the worker picks the job up.

Without `#[WithoutRelations]` (absent on L12), the only defense is to never put models on events. Carry primary keys instead, and re-fetch the relations you actually need in `handle()`.

### The problem

```php
// Event with a model that has eager-loaded relations:
class OrderShipped
{
    public function __construct(public Order $order) {}
}

// Dispatched after: $order = Order::with('items', 'customer', 'shippingAddress')->find(1);
// Queue payload includes Order + Items + Customer + Address — potentially KB+ of JSON.
```

### The L12 fix — carry the ID

```php
class OrderShipped
{
    public function __construct(public int $orderId) {}
}

class SendShipmentNotification implements ShouldQueue
{
    public function handle(OrderShipped $event): void
    {
        // Re-fetch with the relations you actually need:
        $order = Order::with('items')->find($event->orderId);
        // ...
    }
}
```

## Key Points

- Implements `ShouldQueue`
- Executes asynchronously in queue worker
- Listener failure doesn't affect the original request
- Pass IDs in events, not models; re-fetch fresh state in `handle()`
- Can retry on failure
- **L12: no `#[WithoutRelations]`** — passing IDs (not models) in events is the only defense against payload bloat

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
