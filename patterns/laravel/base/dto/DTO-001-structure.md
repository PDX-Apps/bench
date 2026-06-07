# DTO-001-structure

## Pattern

Data Transfer Objects are simple, lightweight, **immutable** structures for passing data and/or instructions between layers.

## What Are DTOs?

DTOs are `readonly` classes that:
- Hold data in a type-safe, structured way
- Can represent data (entities, queries) OR commands (instructions, operations)
- Are **immutable** once constructed
- Can have methods for behavior (transformation, fluent DSL, computation)
- Pass data between layers without coupling

## Example: OrderData (Data Representation)

```php
<?php

declare(strict_types=1);

namespace App\Data;

readonly class OrderData
{
    public function __construct(
        public string $sku,
        public int $quantity,
        public string $customerId,
    ) {
    }
}
```

## Example: SendNotificationData (Command) — PHP 8.5 `clone with`

PHP 8.5 introduces `clone($obj, [...overrides])` — mutate properties during clone in a single expression. This replaces the verbose "construct a new instance with all fields" pattern in fluent DSL methods.

```php
<?php

declare(strict_types=1);

namespace App\Data;

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

    // PHP 8.5 — clone with: clean and intent-revealing
    public function makeImmediate(): self
    {
        return clone($this, ['immediate' => true]);
    }

    public function viaChannel(string $channel): self
    {
        return clone($this, ['channel' => $channel]);
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

### Pre-PHP-8.5 Equivalent (for reference)

The old pattern required listing every field, creating noise that obscured intent:

```php
public function makeImmediate(): self
{
    return new self(
        userId: $this->userId,
        title: $this->title,
        message: $this->message,
        channel: $this->channel,
        immediate: true,           // the only actual change
    );
}
```

`clone with` collapses this to one line and stops drift when fields are added (the new field automatically carries through).

## Example: SearchOrdersData (Query Parameters)

```php
<?php

declare(strict_types=1);

namespace App\Data;

readonly class SearchOrdersData
{
    public function __construct(
        public ?string $sku = null,
        public ?int $minQuantity = null,
        public ?int $maxQuantity = null,
        public int $page = 1,
        public int $perPage = 20,
    ) {
    }

    public function hasFilters(): bool
    {
        return $this->sku !== null
            || $this->minQuantity !== null
            || $this->maxQuantity !== null;
    }

    // Common DSL via clone with
    public function nextPage(): self
    {
        return clone($this, ['page' => $this->page + 1]);
    }
}
```

## Usage: Direct Construction

```php
// Simple direct construction
$order = new OrderData(
    sku: 'WIDGET-001',
    quantity: 3,
    customerId: $user->id,
);

// With data from an array (e.g., inside a controller after validation,
// where $user = $request->user() is already in scope)
$data = new OrderData(
    sku: $input['sku'],
    quantity: $input['quantity'],
    customerId: $user->id,
);
```

## `clone with` Caveats

- The shorthand `clone($obj, [...])` only modifies properties accessible from the calling scope. For `readonly` properties, this is allowed because `clone` is a recognized initialization context.
- If you need to compute a new value based on the existing one, do it inline:
  ```php
  return clone($this, ['count' => $this->count + 1]);
  ```
- Only the listed properties are overridden; everything else carries through unchanged. New properties added later automatically propagate without needing to update every DSL method.

## Key Points

- `readonly` class (immutable)
- Can represent data, commands/instructions, or query parameters
- Construct directly with `new` — simple and explicit
- **PHP 8.5+: use `clone($obj, [...])` for fluent DSL methods** (drops field-list noise + survives field additions)
- Can add computed methods for derived values
- Lives in `app/Data/`
- Keep DTOs simple — no complex business logic
- FormRequests return DTOs via `toDto()` method

## When to Use

**Use DTOs for:**
- HTTP request data (FormRequests → Actions via `toDto()`)
- Commands to services (SendEmailData, ProcessPaymentData)
- Job payloads with type safety
- Event payloads
- Query parameters for filtering/search
