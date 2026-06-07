---
overrides: base/jobs/JOB-001-queued-jobs.md
target: laravel-12
reason: Laravel 12 doesn't have queue attributes (#[Tries], #[Backoff], #[Timeout], #[FailOnTimeout]) — configure via public properties on the job class.
base-hash: 29cabe
---

> ⚠️ **Laravel 12 — property-based job config.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# JOB-001-queued-jobs

## Pattern

Queued background jobs for direct dispatch from application code. Use when work needs to happen async but isn't reacting to a domain event.

## Jobs vs Listeners

| Choose | When |
|--------|------|
| **Job** (this pattern) | Direct dispatch from a controller/Action: `SendOrderReceiptJob::dispatch($orderId)`. Self-contained background work. |
| **Listener** | Automatic reaction to a domain event: `OrderPlaced` event → a notification listener. Decouples publisher from subscriber. |

Both can coexist. Jobs are explicit; listeners are reactive.

## Structure (Laravel 12 — property-based config)

Laravel 12 has no queue attributes; configure retry/timeout policy via public properties on the job class.

```php
<?php

declare(strict_types=1);

namespace App\Jobs;

use App\Actions\SendOrderReceipt;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

/**
 * Sends an order receipt asynchronously. Retries 3 times to ensure delivery.
 */
class SendOrderReceiptJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 3;
    public int $backoff = 5;
    public int $timeout = 120;
    public bool $failOnTimeout = true;

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

### Configuration Properties

| Property | Purpose |
|----------|---------|
| `public int $tries` | Max attempts before terminal failure |
| `public int\|array $backoff` | Retry delays in seconds (scalar or array) |
| `public int $timeout` | Max execution time per attempt |
| `public bool $failOnTimeout` | Fail terminally on timeout instead of retrying |

To strip eager-loaded relations from the serialized payload, call `$this->withoutRelations()` per dispatch (the `#[WithoutRelations]` attribute is not available on L12).

## Queue Routing (Laravel 12)

Configure the queue/connection in the constructor with `onQueue()` / `onConnection()`:

```php
public function __construct(
    public int $orderId,
) {
    $this->onConnection('redis')->onQueue('emails');
}
```

For a single one-off, calling `->onQueue('emails')` on dispatch is also fine.

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
- **L12: set `$tries`/`$backoff`/`$timeout`/`$failOnTimeout` public properties** (no queue attributes)
- Configure queue via `onQueue()`/`onConnection()` in the constructor, or `->onQueue()` on dispatch
- Inject Actions/Services in the `handle()` signature (the container resolves them) — keep business logic out of the job
- `handle()` must be idempotent; implement `failed(\Throwable $e): void` for exhausted retries
- Call `$this->withoutRelations()` on dispatch if eager-loaded models risk oversized payloads
