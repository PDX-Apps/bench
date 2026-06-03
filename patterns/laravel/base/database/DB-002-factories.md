# DB-002-factories

## Pattern

Model factories for generating test data with proper type annotations.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Modules\{Module}\Models\{Model};
use App\Support\PublicId;

/**
 * @extends Factory<{Model}>
 */
class {Model}Factory extends Factory
{
    protected $model = {Model}::class;

    public function definition(): array
    {
        return [
            'public_id' => PublicId::generate(),
            'name' => implode(' ', $this->faker->words(2)),
            'user_id' => User::factory(),
        ];
    }

    /**
     * Configure the factory with hooks (optional).
     */
    public function configure(): static
    {
        return $this->afterCreating(function ({Model} $model): void {
            // Add any post-creation logic here
            // Example: Create related records
        });
    }

    /**
     * Set a specific name.
     */
    public function withName(string $name): static
    {
        return $this->state(fn () => [
            'name' => $name,
        ]);
    }

    /**
     * Attach to a specific user.
     */
    public function forUser(User $user): static
    {
        return $this->state(fn () => [
            'user_id' => $user->id,
        ]);
    }
}
```

## Real Example: HouseholdFactory

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;
use Modules\Household\Models\Household;
use Modules\Household\Models\HouseholdMember;
use App\Support\PublicId;

/**
 * @extends Factory<Household>
 */
class HouseholdFactory extends Factory
{
    protected $model = Household::class;

    public function definition(): array
    {
        return [
            'public_id' => PublicId::generate(),
            'name' => implode(' ', $this->faker->words(2)),
            'user_id' => User::factory(),
            'code' => strtoupper($this->faker->regexify('[A-Z0-9]{6}')),
        ];
    }

    /**
     * Configure the factory to automatically add an owner as a member after creation.
     */
    public function configure(): static
    {
        return $this->afterCreating(function (Household $household): void {
            HouseholdMember::factory()
                ->forHousehold($household)
                ->forUser(User::find($household->user_id))
                ->create();
        });
    }

    public function withCode(string $code): static
    {
        return $this->state(fn () => [
            'code' => $code,
        ]);
    }

    public function withName(string $name): static
    {
        return $this->state(fn () => [
            'name' => $name,
        ]);
    }

    public function forUser(User $user): static
    {
        return $this->state(fn () => [
            'user_id' => $user->id,
        ]);
    }
}
```

## Type Annotations

**Required PHPDoc:**
```php
/**
 * @extends Factory<{Model}>
 */
```

This type annotation:
- Enables IDE autocomplete for factory methods
- Provides type safety for static analysis (PHPStan/Psalm)
- Documents which model the factory creates

## State Method Naming

**Fields:** `withField()`
- `withStatus(string $status)`
- `withCode(string $code)`
- `withName(string $name)`

**Relationships:** `forRelationship()`
- `forUser(User $user)`
- `forHousehold(Household $household)`
- `forOwner(Owner $owner)`

**State methods:**
- Return type must be `static` (not `self`)
- Use `fn () => [...]` for state closure (no parameters needed)

## Configure Method

Use `configure()` for factory hooks:

```php
public function configure(): static
{
    return $this->afterCreating(function ({Model} $model): void {
        // Create related records
        // Set up complex relationships
        // Any post-creation logic
    });
}
```

**Common hooks:**
- `afterCreating()` - After model is created and saved
- `afterMaking()` - After model is made but not saved

## Model Configuration

```php
use Modules\{Module}\Database\Factories\{Model}Factory;

class {Model} extends Model
{
    protected static function newFactory(): {Model}Factory
    {
        return {Model}Factory::new();
    }
}
```

## Usage Examples

```php
// Create single
$household = Household::factory()->create();

// With field state
$household = Household::factory()->withName('Test House')->create();

// With relationship state
$household = Household::factory()->forUser($user)->create();

// Chain multiple states
$household = Household::factory()
    ->withCode('ABC123')
    ->forUser($user)
    ->create();

// Multiple
$households = Household::factory()->count(10)->create();

// Make without saving
$household = Household::factory()->make();
```

## Faker Methods

**Common patterns:**
```php
// Names/text
'name' => implode(' ', $this->faker->words(2)),     // "hello world"
'title' => $this->faker->sentence(3),               // "This is sentence."
'description' => $this->faker->paragraph(),

// Codes/identifiers
'code' => strtoupper($this->faker->regexify('[A-Z0-9]{6}')),  // "A1B2C3"

// Dates
'starts_at' => $this->faker->dateTimeBetween('now', '+1 month'),
'ends_at' => $this->faker->dateTimeBetween('+1 month', '+2 months'),

// Numbers
'amount' => $this->faker->numberBetween(1000, 10000),
'price' => $this->faker->randomFloat(2, 10, 100),   // 2 decimal places
```

## Key Points

- **Location:** `Modules/{Module}/Database/Factories/`
- **Naming:** `{Model}Factory`
- **Type annotation required:** `@extends Factory<{Model}>`
- **Return types:** Use `static` for state methods, `array` for definition
- **PublicId:** Use `PublicId::generate()` for public_id fields
- **State naming:** `withField()` for fields, `forRelationship()` for relationships
- **Configure for hooks:** Use `configure()` method with `afterCreating()` or `afterMaking()`
- **Register in model:** Via `newFactory()` method
