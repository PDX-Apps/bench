# DB-005-eloquent-casts

## Pattern

Custom Eloquent attribute casts for converting between raw DB columns and rich PHP types (value objects, JSON DTOs, computed values).

## When to use

- Value objects backed by one or more DB columns (e.g., `Money` from `amount` + `currency`)
- Mutable JSON columns that should be a typed object (see DATA-003)
- Type coercion beyond Laravel's built-ins

For simple types, use Laravel's built-in casts (`'integer'`, `'datetime'`, enum classes).

## Structure (single-column cast)

```php
<?php

namespace Modules\Bill\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use Illuminate\Database\Eloquent\Model;

/**
 * @implements CastsAttributes<MyVO|null, MyVO|null>
 */
class MyVOCast implements CastsAttributes
{
    public function get(Model $model, string $key, mixed $value, array $attributes): ?MyVO
    {
        return $value === null ? null : MyVO::fromString($value);
    }

    public function set(Model $model, string $key, mixed $value, array $attributes): mixed
    {
        return $value === null ? null : (string) $value;
    }
}
```

## Structure (multi-column cast)

When a value object spans multiple DB columns (Money: `amount` + `currency`), `set()` returns an array mapping column → value:

```php
public function set(Model $model, string $key, mixed $value, array $attributes): array
{
    if ($value instanceof Money) {
        return [
            $key => (int) $value->getAmount(),
            'currency' => $value->getCurrency()->getCode(),
        ];
    }
    // ... handle null, raw int, etc.
}
```

The `attributes` array is mutated for ALL keys returned. Throw `InvalidArgumentException` for unsupported input types.

## Registering on a Model

Use the `casts()` method (Laravel 12 — NOT `$casts` property):

```php
protected function casts(): array
{
    return [
        'amount' => MoneyCast::class,
        'settings' => HouseholdSettingsCast::class,
        'status' => BillStatus::class,
    ];
}
```

## DataAware Casts

Implement `Illuminate\Contracts\Database\Eloquent\DataAwareCastsAttributes` if you need access to ALL model attributes during `set()` (rare — `$attributes` already provides them).

## Rules

- Always implement the `CastsAttributes` contract with `@implements` PHPDoc
- Throw `InvalidArgumentException` for unsupported input types in `set()`
- Handle `null` explicitly in both `get()` and `set()`
- Multi-column casts return an array from `set()`
- Casts live in `Modules/{Module}/app/Casts/`
- Naming: `{Type}Cast` (e.g., `MoneyCast`, `HouseholdSettingsCast`)
- Register in model's `casts()` method, not the deprecated `$casts` property
- Strict types via `declare(strict_types=1)` recommended

## Key Points

- Use casts for value objects, JSON DTOs, and computed types
- Multi-column casts return arrays from `set()` — Laravel writes ALL returned keys
- Always handle null explicitly
- Throw on unsupported types — fail loudly
- See DATA-003-structured-settings for JSON-backed DTO casts
- See CODE-003-enums for enum casting (built-in, no custom cast needed)
