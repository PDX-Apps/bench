# MODEL-002-query-builders

## Pattern

Custom Query Builders to centralize and reuse complex query logic.

## Why

Prevents:
- Duplicating complex queries across the codebase
- Creating service dependencies just to share queries
- Query logic scattered throughout the codebase

## Structure

### Custom Query Builder

```php
<?php

declare(strict_types=1);

namespace App\Models\Builders;

use Illuminate\Database\Eloquent\Builder;

class OrderBuilder extends Builder
{
    /**
     * Orders that have been paid.
     */
    public function paid(): self
    {
        return $this->whereNotNull('paid_at');
    }

    /**
     * Orders placed within the last N days.
     */
    public function recent(int $days = 30): self
    {
        return $this->where('created_at', '>=', now()->subDays($days));
    }

    /**
     * Recently-placed paid orders.
     */
    public function recentlyPaid(int $days = 30): self
    {
        return $this->paid()
            ->recent($days);
    }

    /**
     * Orders in a specific status.
     */
    public function withStatus(OrderStatus $status): self
    {
        return $this->where('status', $status);
    }
}
```

### Model Configuration

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Models\Builders\OrderBuilder;
use Illuminate\Database\Eloquent\Model;

/**
 * @method static OrderBuilder query()
 * @method OrderBuilder newQuery()
 */
class Order extends Model
{
    public function newEloquentBuilder($query): OrderBuilder
    {
        return new OrderBuilder($query);
    }
}
```

Overriding `newEloquentBuilder()` changes the runtime type but not what IDEs and static
analysis infer — `Order::query()` and `$order->newQuery()` still resolve to the base
`Builder` without help. The `@method` annotations above re-type them to `OrderBuilder` so the
custom methods autocomplete and type-check off `query()`/`newQuery()`.

## Usage

Any caller can now reuse these queries:

```php
$orders = Order::query()
    ->recentlyPaid()
    ->get();

// Compose with ad-hoc constraints
$orders = Order::query()
    ->paid()
    ->withStatus(OrderStatus::Fulfilled)
    ->where('total_cents', '>', 10_000)
    ->get();
```

## Key Points

- Lives in `app/Models/Builders/`
- Name pattern: `{Model}Builder`
- Extend `Illuminate\Database\Eloquent\Builder`
- Return `self` for method chaining
- Compose small methods into larger queries
- Override `newEloquentBuilder()` in the model
- Add `@method static {Model}Builder query()` + `@method {Model}Builder newQuery()` PHPDoc on the model so IDEs/static analysis type `query()`/`newQuery()` as the custom builder
- Centralize complex query logic here; callers use builders, never duplicate queries

## When to Use

**Use Custom Query Builders when:**
- The query is used in multiple places
- The query represents business logic (e.g., "paid orders")
- The query is complex (3+ where clauses, joins, subqueries)
- The query will be composed with other queries
- You want IDE autocomplete and type safety

**Use a local scope when** the constraint is a single, simple, rarely-reused, model-specific
`where`. In Laravel 13, declare a local scope with the `#[Scope]` attribute on a method (the
legacy `scopeXxx()` magic-method naming is no longer needed):

```php
use Illuminate\Database\Eloquent\Attributes\Scope;

class Order extends Model
{
    #[Scope]
    protected function draft(Builder $query): void
    {
        $query->whereNull('placed_at');
    }
}

// Called without the "scope" prefix:
Order::query()->draft()->get();
```

**Avoid:**
- Services/repositories created just to share queries (dependency bloat)
- Copy-pasting query logic
- Global scopes (unless multi-tenancy or soft deletes)

## Comparison

| Approach       | Autocomplete | Composable | Testable  | Complexity |
|----------------|--------------|------------|-----------|------------|
| Custom Builder | ✅ Full       | ✅ High     | ✅ Easy    | Low        |
| Local Scope    | ⚠️ Magic     | ✅ High     | ✅ Easy    | Low        |
| Repository     | ✅ Good       | ⚠️ Medium  | ⚠️ Medium | High       |
| Copy-paste     | ❌ None       | ❌ None     | ❌ Hard    | Bloat      |

**Recommendation:** Default to Custom Query Builders for reusable query logic.
