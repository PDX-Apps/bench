# MODEL-002-query-builders

## Pattern

Custom Query Builders to centralize and reuse complex query logic.

## Why

Prevents:
- Duplicating complex queries across services
- Creating service dependencies just to share queries
- Query logic scattered throughout the codebase

## Structure

### Custom Query Builder

```php
<?php

declare(strict_types=1);

namespace Modules\User\Builders;

use Illuminate\Database\Eloquent\Builder;

class UserBuilder extends Builder
{
    /**
     * Users that are activated and verified.
     */
    public function activated(): self
    {
        return $this->where('is_active', true)
            ->whereNotNull('email_verified_at');
    }

    /**
     * Users that are in one or more households.
     */
    public function inHouseholds(): self
    {
        return $this->has('households');
    }

    /**
     * Activated users currently in one or more households.
     */
    public function activatedInHouseholds(): self
    {
        return $this->activated()
            ->inHouseholds();
    }

    /**
     * Users with a specific role.
     */
    public function withRole(string $role): self
    {
        return $this->whereHas('roles', fn($q) => $q->where('name', $role));
    }
}
```

### Model Configuration

```php
<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;
use Modules\User\Builders\UserBuilder;

class User extends Authenticatable
{
    public function newEloquentBuilder($query): UserBuilder
    {
        return new UserBuilder($query);
    }
}
```

## Usage

Now any service can use these queries:

```php
// Service A
$users = User::query()
    ->activatedInHouseholds()
    ->get();

// Service B - same query, no duplication
$activeUsers = User::query()
    ->activatedInHouseholds()
    ->withRole('admin')
    ->get();

// Compose queries
$users = User::query()
    ->activated()
    ->inHouseholds()
    ->where('created_at', '>', now()->subDays(30))
    ->get();
```

## Key Points

- Lives in `Modules/{Module}/Builders/`
- Name pattern: `{Model}Builder`
- Extend `Illuminate\Database\Eloquent\Builder`
- Return `self` for method chaining
- Compose small methods into larger queries
- Override `newEloquentBuilder()` in model
- Centralize ALL complex query logic here
- Services use builders, never duplicate queries

## When to Use

**Use Custom Query Builders when:**
- Query is used in multiple places
- Query represents business logic (e.g., "activated users")
- Query is complex (3+ where clauses, joins, subqueries)
- Query will be composed with other queries
- You want IDE autocomplete and type safety

**Use Local Scopes when:**
- Single, simple where clause
- Rarely reused
- Model-specific constraint

**Avoid:**
- Services/repositories just to share queries (dependency bloat)
- Copy-pasting query logic
- Global scopes (unless multi-tenancy or soft deletes)

## Comparison

| Approach       | Autocomplete | Composable | Testable  | Complexity |
|----------------|--------------|------------|-----------|------------|
| Custom Builder | ✅ Full       | ✅ High     | ✅ Easy    | Low        |
| Local Scopes   | ⚠️ Magic     | ✅ High     | ✅ Easy    | Low        |
| Repository     | ✅ Good       | ⚠️ Medium  | ⚠️ Medium | High       |
| Copy-paste     | ❌ None       | ❌ None     | ❌ Hard    | Bloat      |

**Recommendation:** Default to Custom Query Builders for reusable query logic.
