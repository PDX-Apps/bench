# FACTORY-001-structure

## Pattern

Model factories for generating test data with proper type annotations.

## Structure

```php
<?php

declare(strict_types=1);

namespace Database\Factories;

use App\Models\Order;
use App\Models\User;
use App\Support\PublicId;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Order>
 */
class OrderFactory extends Factory
{
    protected $model = Order::class;

    public function definition(): array
    {
        return [
            'public_id' => PublicId::generate(),
            'reference' => strtoupper($this->faker->bothify('ORD-####??')),
            'total'     => $this->faker->numberBetween(1_000, 100_000),
            'status'    => OrderStatus::Pending,
            'user_id'   => User::factory(),
        ];
    }

    // Field state — withField()
    public function withReference(string $reference): static
    {
        return $this->state(fn () => ['reference' => $reference]);
    }

    // Field state — a named status variation
    public function shipped(): static
    {
        return $this->state(fn () => ['status' => OrderStatus::Shipped]);
    }

    // Relationship state — forRelation()
    public function forCustomer(User $user): static
    {
        return $this->state(fn () => ['user_id' => $user->id]);
    }
}
```

## Type Annotation

The `@extends Factory<{Model}>` PHPDoc is **required** — it enables IDE autocomplete, gives static analysis (PHPStan/Psalm) the model type, and documents what the factory builds.

```php
/**
 * @extends Factory<Order>
 */
```

## State Method Naming

- **Fields:** `withField()` — `withReference(string $ref)`, `withStatus(OrderStatus $s)`
- **Named variations:** a bare verb/adjective — `shipped()`, `cancelled()`
- **Relationships:** `forRelation()` — `forCustomer(User $user)`, `forProduct(Product $product)`
- Return type must be `static` (not `self`); use `fn () => [...]` for the state closure

## Configure / Hooks

Use `configure()` for post-build hooks — the common case is creating related records:

```php
public function configure(): static
{
    return $this->afterCreating(function (Order $order): void {
        OrderItem::factory()->count(3)->forOrder($order)->create();
    });
}
```

- `afterCreating()` — after the model is created and saved (relations, pivots)
- `afterMaking()` — after the model is made but not saved

## Registering on the model

Laravel auto-discovers `Database\Factories\{Model}Factory` for `App\Models\{Model}`. When the factory doesn't follow that convention, point the model at it explicitly:

```php
protected static function newFactory(): OrderFactory
{
    return OrderFactory::new();
}
```

## Usage

```php
Order::factory()->create();                              // one
Order::factory()->shipped()->create();                   // with a state
Order::factory()->forCustomer($user)->create();          // relationship state
Order::factory()->withReference('ORD-0001')->forCustomer($user)->create(); // chained
Order::factory()->count(10)->create();                   // many
Order::factory()->make();                                // without saving
```

## Faker Quick Reference

```php
'name'        => $this->faker->words(2, true),               // "lorem ipsum"
'title'       => $this->faker->sentence(3),
'reference'   => strtoupper($this->faker->bothify('ORD-####??')),
'starts_at'   => $this->faker->dateTimeBetween('now', '+1 month'),
'total'       => $this->faker->numberBetween(1_000, 100_000),
'price'       => $this->faker->randomFloat(2, 10, 100),
```

## Key Points

- **Location:** `database/factories/`; **naming:** `{Model}Factory`
- **Required:** `@extends Factory<{Model}>` PHPDoc
- **Return types:** `static` for state methods, `array` for `definition()`
- Use `PublicId::generate()` for public-id columns
- State naming: `withField()` for fields, `forRelation()` for relationships
- Use `configure()` + `afterCreating()`/`afterMaking()` for hooks
- Nest factories (`User::factory()`) for related records — don't hardcode IDs
