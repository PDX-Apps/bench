# LISTEN-001

## Pattern

Synchronous event listeners execute immediately in the same request cycle.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Listeners;

use Modules\{Module}\Events\{EventName};

class {ActionDescription}
{
    public function handle({EventName} $event): void
    {
        // Execute immediately
        // Keep fast - runs in the request cycle
    }
}
```

## Key Points

- No `ShouldQueue` interface
- Executes synchronously in request cycle
- Keep logic fast (< 100ms)
- Use for critical side effects that must happen immediately
- Exceptions bubble up to the caller (wrap `event()` in try-catch if needed)

## Examples

**Good for sync:**
- Update aggregates/counters
- Create audit logs
- Send critical notifications
- Validate state transitions

**Bad for sync:**
- Send emails
- Call external APIs
- Heavy processing
- Anything that can fail independently
