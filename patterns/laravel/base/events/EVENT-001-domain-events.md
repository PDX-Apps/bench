# EVENT-001-domain-events

## Pattern

Events are emitted when something important happens in the domain.

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
        public {Model} $model,
    ) {
    }
}
```

## Dispatch Strategies

### Manual Dispatch (Recommended)

Dispatch events explicitly in Action classes:

```php
// In CreateEntityAction
$entity = Entity::create([...]);
event(new EntityCreated($entity));
return $entity;
```

**Use when:**
- Events should only fire through business logic layer
- Event needs custom data (not just the model)
- You want to prevent accidental firing in tests/seeders
- Full control over when events fire is required

**Spec decides:** Specs specify which events to dispatch and when.

### Automatic Dispatch (Alternative)

Use `$dispatchesEvents` to map model events to custom events:

```php
class Entity extends Model
{
    protected $dispatchesEvents = [
        'created' => EntityCreated::class,
        'updated' => EntityUpdated::class,
        'deleted' => EntityDeleted::class,
    ];
}
```

**Use when:**
- Simple CRUD operations
- Events always need to fire (audit logs)
- Event only needs the model instance
- Tight coupling between model and events is acceptable

**Limitations:**
- Events fire everywhere (tests, seeders, console)
- Cannot customize event data beyond the model
- Less explicit behavior

## Key Points

- Only `SerializesModels` trait
- `public` properties if event will be queued (required for serialization)
- `private` properties are fine for sync-only events
- Naming: Descriptive of what happened, is happening, or will happen
- Dispatch with `event(new EventName($data))` helper
- Listeners in separate module handle reactions
- **Default approach:** Manual dispatch in Actions (spec can override)

## Examples

**Past tense (already happened):**
- `HouseholdCreated`
- `MemberInvited`
- `PaymentMarkedComplete`

**Future/scheduled:**
- `ReminderWillSend`
- `SubscriptionWillRenew`

**State detection:**
- `LowBalanceDetected`
- `QuotaExceeded`
