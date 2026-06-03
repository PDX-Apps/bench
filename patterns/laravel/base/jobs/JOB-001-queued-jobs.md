# JOB-001-queued-jobs

## Pattern

Queued background jobs for direct dispatch from application code. Use when work needs to happen async but isn't reacting to a domain event.

## Jobs vs Listeners

| Choose | When |
|--------|------|
| **Job** (this pattern) | Direct dispatch from controller/Action: `RecordChangeJob::dispatch(...)`. Self-contained background work. |
| **Listener** (LISTEN-001/002) | Automatic reaction to a domain event: `BillCreated` event → `SendBillCreatedNotification` listener. Decouples publisher from subscriber. |

Both can coexist. Jobs are explicit; Listeners are reactive.

## Structure (Laravel 13 — attribute-based config)

Laravel 13 ships first-party queue attributes. Prefer them over property-based config — the declarative form puts retry/timeout policy at the top of the file where it's visible, and avoids conflicts when you want to compose behaviors.

```php
<?php

declare(strict_types=1);

namespace Modules\Audit\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Queue\Attributes\Tries;
use Illuminate\Queue\Attributes\Backoff;
use Illuminate\Queue\Attributes\Timeout;
use Illuminate\Queue\Attributes\FailOnTimeout;
use Modules\Audit\Actions\RecordChangeAction;

/**
 * Asynchronously records a model change. Retries 3 times to ensure capture.
 */
#[Tries(3)]
#[Backoff(delay: 5)]
#[Timeout(120)]
#[FailOnTimeout]
class RecordChangeJob implements ShouldQueue
{
    use Dispatchable;
    use InteractsWithQueue;
    use Queueable;
    use SerializesModels;

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

### Available Queue Attributes

| Attribute | Purpose | Equivalent property |
|-----------|---------|---------------------|
| `#[Tries(int $count)]` | Max attempts before terminal failure | `public int $tries` |
| `#[Backoff(delay: int)]` or `#[Backoff([5, 10, 30])]` | Retry delays in seconds (scalar or array) | `public int|array $backoff` |
| `#[Timeout(int $seconds)]` | Max execution time per attempt | `public int $timeout` |
| `#[FailOnTimeout]` | Marker — fail terminally on timeout instead of retrying | `public bool $failOnTimeout = true;` |
| `#[WithoutRelations]` | Strip eager-loaded relations during serialization (smaller payload) | `$this->withoutRelations()` per dispatch |

Properties (`public int $tries = 3;`) still work for backward compatibility, but attributes are the new convention.

## Queue Routing (Laravel 13)

Centralized queue/connection routing replaces ad-hoc `onQueue()` calls in constructors:

```php
// In a service provider's boot() method
use Illuminate\Support\Facades\Queue;
use Modules\Audit\Jobs\RecordChangeJob;

Queue::route(RecordChangeJob::class, connection: 'redis', queue: 'audit');
```

Use this when:
- Multiple jobs share the same queue/connection
- The queue choice is environment-driven (different queues per env)
- You want job classes to stay focused on `handle()` logic, not infra

For a single one-off, the constructor `onQueue()` form is still fine.

## Rules

- Pass IDs (or scalar data), NEVER models — re-fetch in `handle()` or via injected Action
- Use constructor property promotion
- Implement `ShouldQueue` + use the four queue traits
- **Prefer `#[Tries(N)]` / `#[Backoff(N)]` / `#[Timeout(N)]` attributes** over public properties (Laravel 13+)
- Configure queue via `Queue::route()` in a provider OR `onQueue()` in constructor
- Inject Actions/Services in `handle()` signature (Laravel resolves them)
- Implement `failed(\Throwable $e): void` to handle exhausted retries
- Use `#[WithoutRelations]` if dispatching with eager-loaded models risks oversized payloads

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
- **L13: declarative attributes for tries/backoff/timeout — readable, composable**
- **L13: `Queue::route()` for centralized job → connection/queue mapping**
- Inject dependencies in `handle()`, not the constructor
- `handle()` must be idempotent
- Implement `failed()` for terminal failure handling
