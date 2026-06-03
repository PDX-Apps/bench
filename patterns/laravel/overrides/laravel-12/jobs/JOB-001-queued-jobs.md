---
overrides: base/jobs/JOB-001-queued-jobs.md
target: laravel-12
reason: Laravel 12 doesn't have queue attributes (#[Tries], #[Backoff], #[Timeout], #[FailOnTimeout]) — configure via public properties on the job class.
base-hash: d571a2
---

> ⚠️ **Laravel 12 — property-based job config.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# JOB-001-queued-jobs

## Pattern

Queued background jobs for direct dispatch from application code. Use when work needs to happen async but isn't reacting to a domain event.

## Jobs vs Listeners

| Choose | When |
|--------|------|
| **Job** (this pattern) | Direct dispatch from controller/Action: `RecordChangeJob::dispatch(...)`. Self-contained background work. |
| **Listener** (LISTEN-001/002) | Automatic reaction to a domain event: `BillCreated` event → `SendBillCreatedNotification` listener. Decouples publisher from subscriber. |

Both can coexist. Jobs are explicit; Listeners are reactive.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Audit\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Modules\Audit\Actions\RecordChangeAction;

/**
 * Asynchronously records a model change. Retries 3 times to ensure capture.
 */
class RecordChangeJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

    public int $tries = 3;

    public function __construct(
        public string $changeableType,
        public int|string $changeableId,
        public string $event,
    ) {
        /** @var string|null $queueName */
        $queueName = config('audit.queue', 'default');
        $this->onQueue($queueName);
    }

    public function handle(RecordChangeAction $action): void
    {
        $action->execute(
            changeableType: $this->changeableType,
            changeableId: $this->changeableId,
            event: $this->event,
        );
    }
}
```

## Rules

- Pass IDs (or scalar data), NEVER models — re-fetch in `handle()` or via injected Action
- Use constructor property promotion
- Implement `ShouldQueue` + use the four queue traits
- Set `public int $tries` for explicit retry count
- Set `public int $timeout` if the job is long-running (default 60s)
- Configure `onQueue()` in constructor when using non-default queues
- Inject Actions/Services in `handle()` signature (Laravel resolves them)
- Implement `failed(\Throwable $e): void` to handle exhausted retries

## Idempotency

Jobs may run more than once (retries, replays). Make `handle()` idempotent:
- Check existing state before acting (`if ($record->alreadyProcessed()) return;`)
- Use unique constraints to prevent duplicates
- Log idempotency decisions for debugging

## Dispatching

```php
RecordChangeJob::dispatch($type, $id, $event);
RecordChangeJob::dispatch($type, $id, $event)->onQueue('priority');
RecordChangeJob::dispatch($type, $id, $event)->delay(now()->addMinutes(5));
```

Dispatch from Actions, not models or controllers.

## Key Points

- Jobs are for explicit async dispatch (different from Listeners — see LISTEN-001/002)
- Always pass IDs, never models (per EVENT-002 serialization rules)
- Set `$tries` and `$timeout` explicitly; never rely on defaults
- Inject dependencies in `handle()`, not the constructor
- `handle()` must be idempotent
- Configure queue name via constructor `onQueue()`
- Implement `failed()` for terminal failure handling
