# EXC-001-domain-exceptions

## Pattern

Custom exception classes for modeling business-rule violations and domain errors as typed exceptions. Improves type safety, error handling, and HTTP response clarity.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Exceptions;

use DomainException;

class OrderAlreadyShippedException extends DomainException
{
    public static function forOrder(int $orderId): self
    {
        return new self("Order {$orderId} has already been shipped.");
    }
}
```

## Choosing a Base Class

| Base | Use When |
|------|----------|
| `DomainException` | Business rule violation (most domain exceptions) |
| `RuntimeException` | Programmer error / unexpected runtime state |
| `InvalidArgumentException` | Bad input to a function (typically internal) |
| `Illuminate\Auth\Access\AuthorizationException` | Authorization failure (returns 403) |
| `Illuminate\Database\Eloquent\ModelNotFoundException` | Model lookup failed (returns 404) |

For HTTP-aware exceptions, extend Laravel's appropriate base class — Laravel handles the HTTP response automatically.

## Static Factory Methods

Prefer named constructors over `new Exception("...")` for clarity:

```php
class InsufficientStockException extends DomainException
{
    public static function forOrder(int $orderId, int $available, int $required): self
    {
        return new self("Order {$orderId} requires {$required} units, only {$available} in stock.");
    }

    public static function forProduct(int $productId): self
    {
        return new self("Product {$productId} is out of stock.");
    }
}

// Usage:
throw InsufficientStockException::forOrder($order->id, $available, $required);
```

## Custom HTTP Response

Implement `render()` to return a custom HTTP response:

```php
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

public function render(Request $request): JsonResponse
{
    return response()->json([
        'message' => $this->getMessage(),
        'code' => 'order_already_shipped',
    ], 409);
}
```

## Custom Reporting

Implement `report()` to customize logging:

```php
public function report(): void
{
    Log::channel('domain-errors')->warning($this->getMessage(), [
        'order_id' => $this->orderId,
    ]);
}
```

Return `false` from `report()` to suppress default reporting (or `bool` from `context()` for conditional).

## Compliance

**NEVER include raw PII in exception messages.** Exceptions get logged automatically — message strings are searchable forever.

```php
// ❌ Wrong — PII in message
throw new InvalidUserException("Email {$user->email} not found.");

// ✅ Right — ID only
throw new InvalidUserException("User {$user->id} not found.");
```

## Key Points

- Live in `app/Exceptions/`; naming `{Condition}Exception` (`OrderAlreadyShippedException`, `InsufficientStockException`)
- Domain-rule violations → `DomainException`; programmer errors → `RuntimeException`
- Use static factory methods (`::forX()`) — never `new` directly in callers
- Implement `render()` for non-standard HTTP status codes (e.g. 409 Conflict); 404/403/422/401 are auto-handled by Laravel
- Implement `report()` for custom logging channels; return `false` to suppress default reporting
- NEVER include PII (email, name, phone) in exception messages — they get logged automatically; use IDs
- Laravel's built-in exceptions cover most HTTP cases — don't reinvent
- `declare(strict_types=1)` recommended
