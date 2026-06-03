# POLICY-001-resource-policies

## Pattern

Authorization policies for controlling access to resources.

## Structure (unchanged from L12)

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Policies;

use App\Models\User;
use Modules\Household\Models\Household;

class HouseholdPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // All authenticated users can list
    }

    public function view(User $user, Household $household): bool
    {
        return $household->isOwner($user);
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Household $household): bool
    {
        return $household->isOwner($user);
    }

    public function delete(User $user, Household $household): bool
    {
        return $household->isOwner($user);
    }
}
```

The policy class itself is the same as L12 — the change is in how controllers invoke it.

## Usage in Controllers (Laravel 13 — Attribute-Based)

Use the `#[Authorize]` attribute per controller method instead of `authorizeResource()` in the constructor:

```php
use Illuminate\Routing\Attributes\Controllers\Authorize;
use Modules\Household\Models\Household;

class HouseholdController
{
    #[Authorize('viewAny', Household::class)]
    public function index() { /* ... */ }

    #[Authorize('view', 'household')]   // route-bound parameter
    public function show(Household $household) { /* ... */ }

    #[Authorize('create', Household::class)]
    public function store(/* ... */) { /* ... */ }

    #[Authorize('update', 'household')]
    public function update(/* ... */) { /* ... */ }

    #[Authorize('delete', 'household')]
    public function destroy(/* ... */) { /* ... */ }
}
```

### Attribute Argument Forms

```php
// Static — class reference (for viewAny, create — no instance yet)
#[Authorize('viewAny', Household::class)]
#[Authorize('create', Household::class)]

// Bound — string parameter name from route (for view/update/delete — instance from route binding)
#[Authorize('view', 'household')]

// Multi-arg — for action policies that take additional context
#[Authorize('invite', ['household', User::class])]
```

### Why Attributes Over `authorizeResource()`

`authorizeResource(Household::class, 'household')` in the constructor relied on convention-based mapping (`index → viewAny`, `show → view`, etc.) which is invisible to a reader scanning the controller. With `#[Authorize]` per method, the policy ability is right next to the method signature — no implicit mapping, no guessing.

The L12 form (`authorizeResource()` in constructor) still works for backward compat, but new code should use attributes.

## Auto-Discovery Requirements (unchanged)

Policies are auto-discovered when ALL of these are true:

1. **File location:** `Modules/{Module}/Policies/` or `app/Policies/`
2. **Naming convention:** Class name is `{Model}Policy` (exact match to model name + "Policy")
3. **Namespace:** Matches directory structure

**Examples:**
- Model: `Modules\Household\Models\Household`
- Policy: `Modules\Household\Policies\HouseholdPolicy` ✅
- Policy: `Modules\Household\Policies\HouseholdAuthPolicy` ❌ (won't auto-discover)

No manual registration needed in service providers.

## Use Model Domain Methods

Policies should delegate to domain methods on the model. If you're writing manual logic like `$user->id === $model->user_id`, that's a smell that the model is missing domain methods.

```php
// ❌ BAD - manual logic in policy
public function accept(User $user, HouseholdInvitation $invitation): bool
{
    return $invitation->invitee_id === $user->id
        || $invitation->invitee_email === $user->email;
}

// ✅ GOOD - delegate to model
public function accept(User $user, HouseholdInvitation $invitation): bool
{
    return $invitation->isInvitee($user);
}
```

If a policy method needs complex logic, add a domain method to the model first. See `MODEL-003-domain-methods`.

## Key Points

- Lives in `Modules/{Module}/Policies/`
- Name pattern: `{Model}Policy` (exact match required for auto-discovery)
- Standard methods: `viewAny`, `view`, `create`, `update`, `delete`
- Return `bool` for authorization result
- Delegate to model domain methods (e.g., `$model->isOwner($user)`)
- Manual logic in policies = missing domain method on model
- Auto-discovered by Laravel when naming convention is followed
- **L13: prefer `#[Authorize('ability', Model::class | 'paramName')]` per controller method**
- For non-resource policies, see `POLICY-002-action-policies`
