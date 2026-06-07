# JOB-001-queued-jobs

## Pattern

Queued background jobs for direct dispatch from application code. Use when work needs to happen async but isn't reacting to a domain event.

## Jobs vs Listeners

| Choose | When |
|--------|------|
| **Job** (this pattern) | Direct dispatch from a controller/Action: `SendOrderReceiptJob::dispatch($orderId)`. Self-contained background work. |
| **Listener** | Automatic reaction to a domain event: `OrderPlaced` event → a notification listener. Decouples publisher from subscriber. |

Both can coexist. Jobs are explicit; listeners are reactive.

## Structure (Laravel 13 — attribute-based config)

Laravel 13 ships first-party queue attributes. Prefer them over property-based config — the declarative form puts retry/timeout policy at the top of the file where it's visible, and avoids conflicts when composing behaviors.

```php
<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Actions\SendOrderReceipt;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\Attributes\Backoff;
use Illuminate\Queue\Attributes\FailOnTimeout;
use Illuminate\Queue\Attributes\Timeout;
use Illuminate\Queue\Attributes\Tries;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\Queueable;
use Illuminate\Queue\SerializesModels;

/**
 * Sends an order receipt asynchronously. Retries 3 times to ensure delivery.
 */
#[Tries(3)]
#[Backoff(delay: 5)]
#[Timeout(120)]
#[FailOnTimeout]
class SendOrderReceiptJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public function __construct(
        public int $orderId,
    ) {
    }

    public function handle(SendOrderReceipt $action): void
    {
        $action->handle($this->orderId);
    }
}
```

### Available Queue Attributes

| Attribute | Purpose | Equivalent property |
|-----------|---------|---------------------|
| `#[Tries(int $count)]` | Max attempts before terminal failure | `public int $tries` |
| `#[Backoff(delay: int)]` or `#[Backoff([5, 10, 30])]` | Retry delays in seconds (scalar or array) | `public int|array $backoff` |
| `#[Timeout(int $seconds)]` | Max execution time per attempt | `public int $timeout` |
| `#[FailOnTimeout]` | Fail terminally on timeout instead of retrying | `public bool $failOnTimeout = true;` |
| `#[WithoutRelations]` | Strip eager-loaded relations during serialization (smaller payload) | `$this->withoutRelations()` per dispatch |

Properties (`public int $tries = 3;`) still work for backward compatibility, but attributes are the new convention.

## Queue Routing (Laravel 13)

Centralized queue/connection routing replaces ad-hoc `onQueue()` calls in constructors:

```php
// In a service provider's boot() method
use App\Jobs\SendOrderReceiptJob;
use Illuminate\Support\Facades\Queue;

Queue::route(SendOrderReceiptJob::class, connection: 'redis', queue: 'emails');
```

Use this when multiple jobs share a queue/connection, the queue choice is environment-driven, or you want job classes to stay focused on `handle()` logic. For a single one-off, calling `->onQueue('emails')` on dispatch is still fine.

## Idempotency

Jobs may run more than once (retries, replays). Make `handle()` idempotent:
- Check existing state before acting (`if ($order->receiptSent()) return;`)
- Use unique constraints to prevent duplicates
- Log idempotency decisions for debugging

## Dispatching

```php
SendOrderReceiptJob::dispatch($order->id);
SendOrderReceiptJob::dispatch($order->id)->onQueue('priority');
SendOrderReceiptJob::dispatch($order->id)->delay(now()->addMinutes(5));
```

Dispatch from Actions, not models or controllers.

## Key Points

- Live in `app/Jobs/`; implement `ShouldQueue` + the four queue traits
- Pass IDs (or scalar data), NEVER models — re-fetch in `handle()` or via the injected Action
- Use constructor property promotion
- **L13: prefer `#[Tries]`/`#[Backoff]`/`#[Timeout]` attributes** over public properties
- Configure queue via `Queue::route()` in a provider, or `->onQueue()` on dispatch
- Inject Actions/Services in the `handle()` signature (the container resolves them) — keep business logic out of the job
- `handle()` must be idempotent; implement `failed(\Throwable $e): void` for exhausted retries
- Use `#[WithoutRelations]` if dispatching with eager-loaded models risks oversized payloads
