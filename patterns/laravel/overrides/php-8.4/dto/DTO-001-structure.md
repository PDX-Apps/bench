---
overrides: base/dto/DTO-001-request-data.md
target: php-8.4
reason: PHP 8.4 doesn't have clone($obj, [...]) syntax — DSL methods on readonly DTOs must use 'new self(...all fields...)' to produce an updated copy.
base-hash: 3d9f71
---

> ⚠️ **PHP 8.4 — no 'clone with' syntax.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# DTO-001-request-data

## Pattern

Data Transfer Objects are simple, lightweight, **immutable** structures for passing data and/or instructions between layers.

## DTO vs Data Object

| Type | Class Style | Mutability | Use Case | FormRequest Method |
|------|-------------|------------|----------|-------------------|
| **DTO** | `readonly class` | Immutable | Request data, commands, events | `toDto()` |
| **Data Object** | Regular `class` | Replaced wholesale | Settings, preferences, config | `toData()` |

For mutable Data Objects (settings, preferences), see `DATA-007-structured-settings`.

## What Are DTOs?

DTOs are `readonly` classes that:
- Hold data in a type-safe, structured way
- Can represent data (entities, queries) OR commands (instructions, operations)
- Are **immutable** once constructed
- Can have methods for behavior (transformation, fluent DSL, computation)
- Pass data between layers without coupling

## Example: HouseholdData (Data Representation)

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Data;

readonly class HouseholdData
{
    public function __construct(
        public string $name,
        public int $maxMembers,
        public string $ownerId,
    ) {
    }
}
```

## Example: SendNotificationData (Command)

```php
<?php

declare(strict_types=1);

namespace Modules\Notification\Data;

readonly class SendNotificationData
{
    public function __construct(
        public string $userId,
        public string $title,
        public string $message,
        public string $channel = 'email',
        public bool $immediate = false,
    ) {
    }

    public function makeImmediate(): self
    {
        return new self(
            userId: $this->userId,
            title: $this->title,
            message: $this->message,
            channel: $this->channel,
            immediate: true,
        );
    }

    public function viaChannel(string $channel): self
    {
        return new self(
            userId: $this->userId,
            title: $this->title,
            message: $this->message,
            channel: $channel,
            immediate: $this->immediate,
        );
    }
}

// Usage with fluent DSL
$notification = new SendNotificationData(
    userId: $user->id,
    title: 'Welcome',
    message: 'Hello!',
);

$notification = $notification
    ->viaChannel('sms')
    ->makeImmediate();
```

## Example: SearchHouseholdsData (Query Parameters)

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Data;

readonly class SearchHouseholdsData
{
    public function __construct(
        public ?string $name = null,
        public ?int $minMembers = null,
        public ?int $maxMembers = null,
        public int $page = 1,
        public int $perPage = 20,
    ) {
    }

    public function hasFilters(): bool
    {
        return $this->name !== null
            || $this->minMembers !== null
            || $this->maxMembers !== null;
    }
}
```

## Usage: Direct Construction

```php
// Simple direct construction
$household = new HouseholdData(
    name: 'Smith Family',
    maxMembers: 5,
    ownerId: $user->id,
);

// With data from an array
$data = new HouseholdData(
    name: $input['name'],
    maxMembers: $input['max_members'],
    ownerId: auth()->id(),
);
```

## Key Points

- `readonly` class (immutable)
- Can represent data, commands/instructions, or query parameters
- Construct directly with `new` - simple and explicit
- Can add fluent DSL methods that return new instances
- Can add computed methods for derived values
- Lives in `Modules/{Module}/Data` namespace
- Keep DTOs simple - no complex business logic
- FormRequests return DTOs via `toDto()` method

## When to Use

**Use DTOs for:**
- HTTP request data (FormRequests → Actions via `toDto()`)
- Commands to services (SendEmailData, ProcessPaymentData)
- Job payloads with type safety
- Event payloads
- Query parameters for filtering/search

**Don't use DTOs for:**
- Domain models (use Eloquent models)
- Database persistence (DTOs are ephemeral)
- Complex business logic (use Actions)
- Mutable settings/preferences (see `DATA-007-structured-settings`)
