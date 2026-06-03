---
overrides: base/listeners/LISTEN-002-queued-listeners.md
target: laravel-12
reason: Laravel 12 doesn't have #[WithoutRelations] for listeners — payloads include all eager-loaded relations on the event. Rely on the existing rule of passing IDs in events (not models) to keep payloads small.
base-hash: 51bc10
---

> ⚠️ **Laravel 12 — no #[WithoutRelations] attribute.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# LISTEN-002

## Pattern

Queued event listeners execute asynchronously in background jobs.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Listeners;

use Illuminate\Contracts\Queue\ShouldQueue;
use Modules\{Module}\Events\{EventName};
use Modules\{Module}\Models\{Model};

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

## Key Points

- Implements `ShouldQueue`
- Executes asynchronously in queue worker
- Listener failure doesn't affect original request
- See `EVENT-002` for passing IDs instead of models
- Can retry on failure

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
