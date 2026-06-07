# POLICY-001-resource-policies

## Pattern

Authorization policies for controlling access to resources.

## Structure (unchanged from L12)

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

The policy class itself is the same as L12 — the change is in how controllers invoke it.

## Usage in Controllers (Laravel 13 — Attribute-Based)

Use the `#[Authorize]` attribute per controller method instead of `authorizeResource()` in the constructor:

```php
use App\Models\Order;
use Illuminate\Routing\Attributes\Controllers\Authorize;

class OrderController
{
    #[Authorize('viewAny', Order::class)]
    public function index() { /* ... */ }

    #[Authorize('view', 'order')]   // route-bound parameter
    public function show(Order $order) { /* ... */ }

    #[Authorize('create', Order::class)]
    public function store(/* ... */) { /* ... */ }

    #[Authorize('update', 'order')]
    public function update(/* ... */) { /* ... */ }

    #[Authorize('delete', 'order')]
    public function destroy(/* ... */) { /* ... */ }
}
```

### Attribute Argument Forms

```php
// Static — class reference (for viewAny, create — no instance yet)
#[Authorize('viewAny', Order::class)]
#[Authorize('create', Order::class)]

// Bound — string parameter name from route (for view/update/delete — instance from route binding)
#[Authorize('view', 'order')]

// Multi-arg — for action policies that take additional context
#[Authorize('assign', ['order', User::class])]
```

### Why Attributes Over `authorizeResource()`

`authorizeResource(Order::class, 'order')` in the constructor relied on convention-based mapping (`index → viewAny`, `show → view`, etc.) which is invisible to a reader scanning the controller. With `#[Authorize]` per method, the policy ability is right next to the method signature — no implicit mapping, no guessing.

The L12 form (`authorizeResource()` in constructor) still works for backward compat, but new code should use attributes. `#[Authorize]` *is* the `can` middleware — never also add `->can()` on the route for the same action.

## Auto-Discovery Requirements (unchanged)

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
- **L13: prefer `#[Authorize('ability', Model::class | 'paramName')]` per controller method**; never also `->can()` on the route
