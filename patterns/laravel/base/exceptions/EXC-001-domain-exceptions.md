# EXC-001-domain-exceptions

## Pattern

Custom exception classes for modeling business-rule violations and domain errors as typed exceptions. Improves type safety, error handling, and HTTP response clarity.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Exceptions;

use DomainException;

class InvitationAlreadyProcessedException extends DomainException
{
    public static function forInvitation(int $invitationId): self
    {
        return new self("Invitation {$invitationId} has already been processed.");
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
class InsufficientFundsException extends DomainException
{
    public static function forBill(int $billId, int $available, int $required): self
    {
        return new self("Bill {$billId} requires {$required} cents, only {$available} available.");
    }

    public static function forUser(int $userId): self
    {
        return new self("User {$userId} has no payment method on file.");
    }
}

// Usage:
throw InsufficientFundsException::forBill($bill->id, $available, $required);
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
        'code' => 'invitation_already_processed',
    ], 409);
}
```

## Custom Reporting

Implement `report()` to customize logging:

```php
public function report(): void
{
    Log::channel('domain-errors')->warning($this->getMessage(), [
        'invitation_id' => $this->invitationId,
    ]);
}
```

Return `false` from `report()` to suppress default reporting (or `bool` from `context()` for conditional).

## Compliance

**NEVER include raw PII in exception messages.** Exceptions get logged automatically — message strings are searchable forever. See DATA-001-compliance-and-logging.

```php
// ❌ Wrong — PII in message
throw new InvalidUserException("Email {$user->email} not found.");

// ✅ Right — ID only
throw new InvalidUserException("User {$user->id} not found.");
```

## Rules

- Live in `Modules/{Module}/app/Exceptions/`
- Naming: `{Condition}Exception` — `InvitationAlreadyProcessedException`, `InsufficientFundsException`
- Extend the appropriate base (`DomainException` for business rules)
- Use static factory methods (`::forX()`) — never `new` directly in callers
- Implement `render()` for custom HTTP responses (404/403 are auto-handled by Laravel)
- Implement `report()` to customize logging
- **Never include PII in messages** (per DATA-001)
- Strict types via `declare(strict_types=1)` recommended

## Key Points

- Domain rule violations → `DomainException`, programmer errors → `RuntimeException`
- Static factory methods > raw constructor calls
- Implement `render()` for non-standard HTTP status codes (e.g., 409 Conflict)
- Implement `report()` for custom logging channels
- NEVER include PII (email, name, phone) in exception messages
- Laravel's built-in exceptions (404/403/422/401) cover most HTTP cases — don't reinvent
