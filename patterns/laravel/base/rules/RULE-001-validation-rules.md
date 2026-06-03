# RULE-001-validation-rules

## Pattern

Custom validation rule classes implementing Laravel's `ValidationRule` contract. Used in FormRequests when built-in validation rules don't cover the business constraint.

## Structure

```php
<?php

namespace Modules\Currency\Rules;

use Closure;
use Illuminate\Contracts\Validation\ValidationRule;

class ValidCurrency implements ValidationRule
{
    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (!is_string($value) || !in_array($value, ['USD', 'EUR', 'JPY'], true)) {
            $fail('The :attribute must be a supported currency code.');
        }
    }
}
```

## DataAwareRule (cross-field validation)

When a rule depends on other fields in the request (e.g., precision depends on currency):

```php
use Illuminate\Contracts\Validation\DataAwareRule;
use Illuminate\Contracts\Validation\ValidationRule;

class ValidMoneyAmount implements DataAwareRule, ValidationRule
{
    protected array $data = [];

    public function setData(array $data): static
    {
        $this->data = $data;
        return $this;
    }

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        $currency = $this->data['currency'] ?? null;
        // ... use $currency to determine precision, then validate $value
    }
}
```

Laravel auto-injects request data via `setData()`.

## Configurable Rules

Constructor parameters for reuse with different configs:

```php
class ValidCurrency implements ValidationRule
{
    public function __construct(protected ?string $allowedOnly = null) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if ($this->allowedOnly !== null && $value !== $this->allowedOnly) {
            $fail("The :attribute must be {$this->allowedOnly}.");
        }
    }
}

// Usage in FormRequest:
'currency' => ['required', new ValidCurrency('USD')],
```

## Usage in FormRequests

```php
public function rules(): array
{
    return [
        'amount' => ['required', new ValidMoneyAmount()],
        'currency' => ['required', new ValidCurrency()],
    ];
}
```

## Rules

- Implement `Illuminate\Contracts\Validation\ValidationRule` (Laravel 12 — NOT the deprecated `Rule` interface)
- Single method: `validate(string $attribute, mixed $value, Closure $fail): void`
- Call `$fail('message')` to fail validation; don't throw exceptions
- Use `DataAwareRule` interface for cross-field validation
- Constructor parameters for configurable rules
- Live in `Modules/{Module}/app/Rules/`
- Naming: descriptive (e.g., `ValidMoneyAmount`, `UniqueAcrossModules`) — no `Rule` suffix needed
- Use `:attribute` placeholder in error messages — Laravel substitutes it
- Strict types via `declare(strict_types=1)` recommended

## Key Points

- Implement `ValidationRule` (call `$fail()` not throw)
- Add `DataAwareRule` when you need other request fields
- Constructor for per-instance configuration
- Use in FormRequest as instance: `new MyRule(config)` — not as a class string
- See HTTP-002-form-requests for FormRequest patterns
- See VAL-* docs in module folders for project-specific validation specifications
