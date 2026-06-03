# DB-003-seeders

## Pattern

Database seeders for populating data during development and testing.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Database\Seeders;

use Illuminate\Database\Seeder;
use Modules\Household\Models\Household;
use App\Models\User;

class HouseholdSeeder extends Seeder
{
    public function run(): void
    {
        // Create households for existing users
        User::query()
            ->inRandomOrder()
            ->limit(5)
            ->each(fn(User $user) =>
                Household::factory()
                    ->count(2)
                    ->forUser($user)
                    ->create()
            );

        // Create standalone households
        Household::factory()
            ->count(10)
            ->create();
    }
}
```

## Registration

Register in `DatabaseSeeder`:

```php
public function run(): void
{
    $this->call([
        HouseholdSeeder::class,
    ]);
}
```

## Usage

```php
// Run all seeders
php artisan db:seed

// Run specific seeder
php artisan db:seed --class=HouseholdSeeder

// Fresh migration with seeding
php artisan migrate:fresh --seed
```

## Key Points

- Lives in `Modules/{Module}/Database/Seeders/`
- Name pattern: `{Module}Seeder` or `{Model}Seeder`
- Extend `Illuminate\Database\Seeder`
- Use factories to create data
- Keep seeders idempotent when possible
- Seeders are for development/testing, not production data
- Call from `DatabaseSeeder` when needed by user
