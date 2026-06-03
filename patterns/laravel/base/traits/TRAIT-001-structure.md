# TRAIT-001-structure

## Pattern

Traits provide reusable behavior that can be composed into classes. Follow Laravel's naming conventions and organizational patterns.

## Naming Conventions

Laravel uses specific prefixes based on trait purpose:

| Prefix | Purpose | Example |
|--------|---------|---------|
| `Has{Thing}` | Model has a feature/relationship | `HasFactory`, `HasUuids`, `HasTimestamps` |
| `InteractsWith{Thing}` | Provides interaction methods | `InteractsWithSession`, `InteractsWithDatabase` |
| `Can{Action}` | Provides ability/permission | `CanResetPassword` |
| `Handles{Thing}` | Handles/processes something | `HandlesAuthorization` |
| `{Verb}s{Thing}` | Action-oriented behavior | `BuildsQueries`, `ManagesTransactions` |

## Directory Structure

Traits live in a `Concerns/` directory within their relevant namespace:

```
Modules/{Module}/
├── Models/
│   └── Concerns/                    # Model traits
│       ├── HasPublicId.php
│       ├── HasOwnership.php
│       └── BelongsToHousehold.php
├── Http/
│   └── Controllers/
│       └── Concerns/                # Controller traits
│           └── HandlesApiResponses.php
└── tests/
    └── Concerns/                    # Test traits
        ├── InteractsWithInvitations.php
        └── InteractsWithHouseholds.php
```

For app-level:
```
app/
├── Models/
│   └── Concerns/
│       ├── HasUlid.php
│       └── HasAuditTrail.php
├── Http/
│   └── Controllers/
│       └── Concerns/
│           └── HandlesApiResponses.php
└── Services/
    └── Concerns/
        └── LogsActivity.php

tests/
└── Concerns/
    ├── InteractsWithUsers.php
    └── CreatesTestData.php
```

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Models\Concerns;

use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Modules\{Module}\Models\Household;

/**
 * Provides household relationship and ownership methods.
 *
 * Use in models that belong to a household.
 *
 * @property int $household_id
 * @property-read Household $household
 */
trait BelongsToHousehold
{
    /**
     * Get the household this model belongs to.
     *
     * @return BelongsTo<Household, $this>
     */
    public function household(): BelongsTo
    {
        return $this->belongsTo(Household::class);
    }

    /**
     * Check if this model belongs to the given household.
     */
    public function belongsToHousehold(int|Household $household): bool
    {
        $householdId = $household instanceof Household ? $household->id : $household;

        return $this->household_id === $householdId;
    }

    /**
     * Scope to filter by household.
     *
     * @param \Illuminate\Database\Eloquent\Builder<static> $query
     * @return \Illuminate\Database\Eloquent\Builder<static>
     */
    public function scopeForHousehold($query, int|Household $household)
    {
        $householdId = $household instanceof Household ? $household->id : $household;

        return $query->where('household_id', $householdId);
    }
}
```

## When to Create Traits

**Create a trait when:**
- Behavior is reused across **3+ classes**
- Logic is cohesive and self-contained
- Multiple unrelated classes need the same capability
- You want to compose behavior without inheritance

**Don't create traits for:**
- One-off methods (keep in class)
- Behavior used by only 1-2 classes
- Complex logic that should be a service
- State that should be in a base class

## Trait Categories

### Model Traits

Provide reusable model behavior:

```php
<?php

declare(strict_types=1);

namespace App\Models\Concerns;

use App\Support\PublicId;

/**
 * Provides ULID-based public ID generation.
 *
 * @property string $public_id
 */
trait HasPublicId
{
    public static function bootHasPublicId(): void
    {
        static::creating(static function ($model): void {
            if (empty($model->public_id)) {
                $model->public_id = PublicId::generate();
            }
        });
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }
}
```

### Test Traits

Provide reusable test helpers (see TEST-003-test-traits):

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Tests\Concerns;

use Modules\Household\Models\HouseholdInvitation;
use PHPUnit\Framework\MockObject\Stub;

/**
 * Test helpers for HouseholdInvitation mocks and stubs.
 */
trait InteractsWithInvitations
{
    protected function createInvitationStub(array $attributes = []): HouseholdInvitation&Stub
    {
        // ...
    }
}
```

### Controller Traits

Share controller behavior:

```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers\Concerns;

use Illuminate\Http\JsonResponse;

/**
 * Standardized API response methods.
 */
trait HandlesApiResponses
{
    protected function successResponse(mixed $data, int $status = 200): JsonResponse
    {
        return response()->json(['data' => $data], $status);
    }

    protected function errorResponse(string $message, int $status = 400): JsonResponse
    {
        return response()->json(['error' => $message], $status);
    }
}
```

## Boot Methods

For traits that need initialization, use the `boot{TraitName}` convention:

```php
trait HasPublicId
{
    /**
     * Boot the trait (called automatically by Eloquent).
     */
    public static function bootHasPublicId(): void
    {
        static::creating(static function ($model): void {
            // Initialization logic
        });
    }
}
```

Laravel automatically calls `boot{TraitName}` when the model boots.

## Trait Composition

Traits can use other traits:

```php
trait HasFullAuditTrail
{
    use HasTimestamps;
    use HasSoftDeletes;
    use LogsActivity;
}
```

## Key Points

- **Naming:** Follow Laravel conventions (`Has*`, `InteractsWith*`, `Handles*`)
- **Location:** `Concerns/` directory within relevant namespace
- **Threshold:** Create when behavior is reused in 3+ classes
- **Cohesion:** Trait should do one thing well
- **Boot methods:** Use `boot{TraitName}` for initialization
- **PHPDoc:** Document `@property` for attributes trait provides
- **Type hints:** Use `$this` in return types for fluent methods
- **Scope methods:** Prefix with `scope` for query scopes

## Related

- `TRAIT-002-test-traits` - Test-specific trait patterns
- `MODEL-001-structure` - Model patterns
