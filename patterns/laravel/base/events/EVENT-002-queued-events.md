# EVENT-002

## Pattern

Custom domain events intended for queued listeners should pass IDs, not full model instances.

**Note:** This applies to custom events you create, not Laravel's built-in model events (`created`, `updated`, etc.) which pass models and are synchronous by default.

## Dependencies

- `listeners/LISTEN-002.md` - Queued listeners

## Why

Passing full models to queued events causes:
- **Serialization issues**: Complex relationships, circular references
- **Job size errors**: SQS has a 256 KB limit, Redis has memory constraints
- **Race conditions**: Model state may change between dispatch and handling
- **Stale data**: Listener receives outdated model snapshot

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Events;

use Illuminate\Queue\SerializesModels;

class {EventName}
{
    use SerializesModels;

    public function __construct(
        public int $resourceId,
        public ?array $metadata = null,
    ) {
    }
}
```

## Key Points

- Pass IDs, not models (for queued events)
- Re-fetch in listener for fresh state
- Handle model deletion gracefully
- Optional metadata for context (arrays, primitives only)
- Sync events (LISTEN-001) can still pass full models

## When to Use

**Pass IDs when:**
- Event has queued listeners
- Model has relationships
- Job might execute minutes/hours later
- Using SQS or size-constrained queue driver

**Pass models when:**
- All listeners are synchronous (LISTEN-001)
- Simple value objects/DTOs
- Model is immutable

## Examples

```php
// Good - Custom domain event for queued listeners
event(new HouseholdCreated(
    householdId: $household->id,
    metadata: ['owner_id' => $user->id]
));

// Bad - Queued event with a full model (serialization issues)
event(new HouseholdCreated(
    household: $household // May have relationships, gets stale
));

// OK - Sync event can pass model
event(new HouseholdValidated($household)); // No ShouldQueue listeners

// Also OK - Laravel's model events pass models (sync by default)
// Model::created(fn($model) => ...) // Model event observers are sync
```
