---
overrides: base/policies/POLICY-001-resource-policies.md
target: laravel-12
reason: Laravel 12 wires policies to controllers via authorizeResource() in the constructor — no per-method #[Authorize] attribute.
base-hash: e0965f
---

> ⚠️ **Laravel 12 — constructor-based policy wiring.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# POLICY-001-resource-policies

## Pattern

Authorization policies for controlling access to resources.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Order;
use App\Models\User;

class OrderPolicy
{
    public function viewAny(User $user): bool
    {
        return true; // All authenticated users can list
    }

    public function view(User $user, Order $order): bool
    {
        return $order->isOwnedBy($user);
    }

    public function create(User $user): bool
    {
        return true;
    }

    public function update(User $user, Order $order): bool
    {
        return $order->isOwnedBy($user);
    }

    public function delete(User $user, Order $order): bool
    {
        return $order->isOwnedBy($user);
    }
}
```

The policy class itself is identical across versions — the change is in how controllers invoke it.

## Usage in Controllers (Laravel 12 — `authorizeResource()`)

Use `authorizeResource()` in the controller constructor. It automatically maps controller methods to policy methods (only for methods that exist in both):

```php
use App\Models\Order;

class OrderController
{
    public function __construct()
    {
        $this->authorizeResource(Order::class, 'order');
    }

    // Automatic mapping:
    // index   -> viewAny
    // show    -> view
    // store   -> create
    // update  -> update
    // destroy -> delete
}
```

No need to specify `->only()` — it only registers authorization for methods that exist in the policy. `authorizeResource()` *is* the `can` middleware — never also add `->can()` on the route for the same action.

## Auto-Discovery Requirements

Policies are auto-discovered when ALL of these are true:

1. **File location:** `app/Policies/`
2. **Naming convention:** Class name is `{Model}Policy` (exact match to model name + "Policy")
3. **Namespace:** Matches directory structure

**Examples:**
- Model: `App\Models\Order`
- Policy: `App\Policies\OrderPolicy` ✅
- Policy: `App\Policies\OrderAuthPolicy` ❌ (won't auto-discover)

No manual registration needed in service providers.

## Use Model Domain Methods

Policies should delegate to domain methods on the model. If you're writing manual logic like `$user->id === $model->user_id`, that's a smell that the model is missing domain methods.

```php
// ❌ BAD - manual logic in policy
public function accept(User $user, Invitation $invitation): bool
{
    return $invitation->invitee_id === $user->id
        || $invitation->invitee_email === $user->email;
}

// ✅ GOOD - delegate to model
public function accept(User $user, Invitation $invitation): bool
{
    return $invitation->isInvitee($user);
}
```

If a policy method needs complex logic, add a domain method to the model first.

## Key Points

- Lives in `app/Policies/`
- Name pattern: `{Model}Policy` (exact match required for auto-discovery)
- Standard methods: `viewAny`, `view`, `create`, `update`, `delete`
- Return `bool` for authorization result
- Delegate to model domain methods (e.g., `$model->isOwnedBy($user)`)
- Manual logic in policies = missing domain method on model
- Auto-discovered by Laravel when naming convention is followed
- **L12: wire via `authorizeResource(Model::class, 'param')` in the controller constructor**; never also `->can()` on the route
