---
overrides: base/policies/POLICY-001-resource-policies.md
target: laravel-12
reason: Laravel 12 wires policies to controllers via authorizeResource() in the constructor — no per-method #[Authorize] attribute.
base-hash: 315035
---

> ⚠️ **Laravel 12 — constructor-based policy wiring.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# POLICY-001-resource-policies

## Pattern

Authorization policies for controlling access to resources.

## Structure

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

## Usage in Controllers

Use `authorizeResource()` in the constructor. It automatically maps controller methods to policy methods (only for methods that exist in both):

```php
class HouseholdController
{
    public function __construct()
    {
        $this->authorizeResource(Household::class, 'household');
    }

    // Automatic mapping:
    // index  -> viewAny
    // show   -> view
    // store  -> create
    // update -> update
    // destroy -> delete
}
```

No need to specify `->only()` - it only registers authorization for methods that exist in the policy.

## Auto-Discovery Requirements

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
- Use `authorizeResource()` in controller constructor
- For non-resource policies, see `POLICY-002-action-policies`
