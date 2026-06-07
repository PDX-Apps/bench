# CAST-001-structure

## Pattern

Custom Eloquent attribute casts for converting between raw DB columns and rich PHP types (value objects, typed JSON objects, computed values). Two shapes: **single-column** (one DB column ↔ one PHP type) and **multi-column** (multiple DB columns ↔ one PHP type like `Money` from `amount` + `currency`).

For simple types, use Laravel's built-in casts (`'integer'`, `'datetime'`, enum classes — backed enums cast natively).

## Structure (single-column cast)

```php
<?php

declare(strict_types=1);

namespace App\Casts;

use App\ValueObjects\MyVO;
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

When a value object spans multiple DB columns (e.g., `Money` = `amount` + `currency`), `set()` returns an **array** mapping column → value. Laravel writes all returned keys to the model's attributes.

```php
public function set(Model $model, string $key, mixed $value, array $attributes): array
{
    if ($value instanceof Money) {
        return [
            $key       => (int) $value->getAmount(),       // amount column
            'currency' => $value->getCurrency()->getCode(), // currency column
        ];
    }

    throw new InvalidArgumentException('Expected Money instance.');
}
```

## Registering on a Model

```php
protected function casts(): array
{
    return [
        'amount'   => MoneyCast::class,
        'settings' => UserSettingsCast::class,
        'status'   => OrderStatus::class,   // backed enum — native cast, no custom class
    ];
}
```

## Gotchas

- **Multi-column `set()` returns an array; single-column returns a scalar.** Laravel uses the return shape to decide whether to write multiple columns or one.
- **`null` propagation**: handle null explicitly in both `get()` and `set()` so models reading/writing optional columns don't blow up.
- **Throwing on unexpected input**: `set()` is where the cast meets untyped data. Throwing on garbage input fails loudly; returning `null` silently loses data.
- **Built-in backed enums don't need a custom cast** — Laravel handles `'status' => OrderStatus::class` natively.
