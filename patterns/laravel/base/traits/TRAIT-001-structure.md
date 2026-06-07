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
app/
├── Models/
│   └── Concerns/                    # Model traits
│       ├── HasReference.php
│       └── BelongsToTeam.php
├── Http/
│   └── Controllers/
│       └── Concerns/                # Controller traits
│           └── HandlesApiResponses.php
└── Services/
    └── Concerns/
        └── LogsActivity.php

tests/
└── Concerns/                        # Test traits
    ├── InteractsWithOrders.php
    └── CreatesTestData.php
```

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Models\Concerns;

use App\Models\Team;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Provides the team relationship and membership helpers.
 *
 * Use in models that belong to a team.
 *
 * @property int $team_id
 * @property-read Team $team
 */
trait BelongsToTeam
{
    /**
     * Get the team this model belongs to.
     *
     * @return BelongsTo<Team, $this>
     */
    public function team(): BelongsTo
    {
        return $this->belongsTo(Team::class);
    }

    /**
     * Check if this model belongs to the given team.
     */
    public function belongsToTeam(int|Team $team): bool
    {
        $teamId = $team instanceof Team ? $team->id : $team;

        return $this->team_id === $teamId;
    }

    /**
     * Scope to filter by team.
     *
     * @param \Illuminate\Database\Eloquent\Builder<static> $query
     * @return \Illuminate\Database\Eloquent\Builder<static>
     */
    public function scopeForTeam($query, int|Team $team)
    {
        $teamId = $team instanceof Team ? $team->id : $team;

        return $query->where('team_id', $teamId);
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

use Illuminate\Support\Str;

/**
 * Generates a unique human-facing reference on creation.
 *
 * @property string $reference
 */
trait HasReference
{
    public static function bootHasReference(): void
    {
        static::creating(static function ($model): void {
            if (empty($model->reference)) {
                $model->reference = strtoupper(Str::random(10));
            }
        });
    }
}
```

### Test Traits

Provide reusable test helpers (the test-traits pattern covers these in depth):

```php
<?php

declare(strict_types=1);

namespace Tests\Concerns;

use App\Models\Invitation;
use PHPUnit\Framework\MockObject\Stub;

/**
 * Test helpers for Invitation mocks and stubs.
 */
trait InteractsWithInvitations
{
    protected function createInvitationStub(array $attributes = []): Invitation&Stub
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
trait HasReference
{
    /**
     * Boot the trait (called automatically by Eloquent).
     */
    public static function bootHasReference(): void
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
