---
overrides: base/dto/DTO-001-structure.md
target: php-8.4
reason: PHP 8.4 doesn't have clone($obj, [...]) syntax — DSL methods on readonly DTOs must use 'new self(...all fields...)' to produce an updated copy.
base-hash: 7c06b9
---

> ⚠️ **PHP 8.4 — no 'clone with' syntax.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

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

## Example: SendNotificationData (Command)

On PHP 8.4 there is no `clone($obj, [...overrides])` expression. Fluent DSL methods on a `readonly` DTO must build a fresh instance with `new self(...)`, listing every field explicitly.

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

Every field must be listed in each DSL method. When a new field is added, every method that rebuilds the DTO must be updated to carry it through. (PHP 8.5's `clone($obj, [...])` removes this noise — see the base pattern.)

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

    // Common DSL — rebuild with all fields (no clone with on 8.4)
    public function nextPage(): self
    {
        return new self(
            sku: $this->sku,
            minQuantity: $this->minQuantity,
            maxQuantity: $this->maxQuantity,
            page: $this->page + 1,
            perPage: $this->perPage,
        );
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

## Key Points

- `readonly` class (immutable)
- Can represent data, commands/instructions, or query parameters
- Construct directly with `new` — simple and explicit
- **PHP 8.4: rebuild with `new self(...)` for fluent DSL methods** (list every field; no `clone with`)
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
