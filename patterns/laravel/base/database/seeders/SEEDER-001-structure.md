# SEEDER-001-structure

## Pattern

Database seeders for populating data during development and testing.

## Structure

```php
<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Seeder;

class OrderSeeder extends Seeder
{
    public function run(): void
    {
        // Create orders for existing users
        User::query()
            ->inRandomOrder()
            ->limit(5)
            ->each(fn (User $user) => Order::factory()
                ->count(2)
                ->forUser($user)
                ->create());

        // Create standalone orders
        Order::factory()
            ->count(10)
            ->create();
    }
}
```

## Reference Data (Idempotent)

The seeder above creates throwaway dev/test data. **Reference / lookup data** (roles,
permissions, plans, categories) is different: it must exist in production and the seeder runs on
every deploy, so it must be **idempotent** — re-running it must never duplicate rows.

For a flat set of rows, `upsert()` does it in **one query, no loop** — match on a natural key:

```php
class PlanSeeder extends Seeder
{
    public function run(): void
    {
        Plan::upsert(
            [
                ['slug' => 'free', 'name' => 'Free', 'price_cents' => 0],
                ['slug' => 'pro', 'name' => 'Pro', 'price_cents' => 1900],
            ],
            uniqueBy: ['slug'],              // natural key — match on this
            update: ['name', 'price_cents'], // columns to refresh on conflict
        );
    }
}
```

Reach for `updateOrCreate()` / `firstOrCreate()` (one call per row, in a loop) only when you
need per-row model events, casts, or logic — `upsert()` writes directly and fires no model
events.

**Prefer an enum over a reference table for fixed status/type sets.** If a value set is fixed in
code (order status, invitation type), model it as a PHP enum cast — no table, no seeder needed. Use
a reference *table* only when rows are user-editable or carry extra columns (a `plans` table with
prices, a `categories` table users manage).

Seeding actual production *business* data (real customers, transactions) is not a seeder
concern — that's a one-off data import/migration.

## Registration

Register in `DatabaseSeeder`:

```php
public function run(): void
{
    $this->call([
        OrderSeeder::class,
    ]);
}
```

## Usage

```php
// Run all seeders
php artisan db:seed

// Run a specific seeder
php artisan db:seed --class=OrderSeeder

// Fresh migration with seeding
php artisan migrate:fresh --seed
```

## Key Points

- Lives in `database/seeders/`
- Name pattern: `{Model}Seeder`
- Extend `Illuminate\Database\Seeder`
- Dev/test data: use factories — never hand-craft records
- **Reference/lookup data (roles, plans, categories): idempotent** — `updateOrCreate`/`upsert` on a natural key, safe to re-run every deploy
- Prefer a PHP enum over a reference table for fixed status/type sets
- Actual production business data is not a seeder concern (use a data import/migration)
- Call from `DatabaseSeeder` when needed
