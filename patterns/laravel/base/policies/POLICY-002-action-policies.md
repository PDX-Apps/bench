# POLICY-002-action-policies

## Pattern

Authorization policies for non-CRUD actions (accept, deny, assign, cancel, etc.).

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Policies;

use App\Models\Invitation;
use App\Models\User;

class InvitationPolicy
{
    public function accept(User $user, Invitation $invitation): bool
    {
        return $invitation->isInvitee($user);
    }

    public function deny(User $user, Invitation $invitation): bool
    {
        return $invitation->isInvitee($user);
    }

    public function revoke(User $user, Invitation $invitation): bool
    {
        return $invitation->isSender($user);
    }
}
```

## Usage in Controllers (Laravel 13 — Attribute-Based)

Non-CRUD actions live on invokable or grouped controllers (the route file maps the URL; it does
**not** carry authorization). Authorize the action with `#[Authorize('ability', 'paramName')]`
on the controller method — the same attribute used for resource policies. `#[Authorize]` *is*
the `can` middleware, so the ability runs before the action; never also add `->can()` on the
route for the same action.

```php
use App\Models\Invitation;
use Illuminate\Routing\Attributes\Controllers\Authorize;

class AcceptInvitationController
{
    #[Authorize('accept', 'invitation')]   // route-bound {invitation}
    public function __invoke(Invitation $invitation)
    {
        // ...
    }
}
```

```php
// routes — mapping only, no ->can()
Route::post('invitations/{invitation}/accept', AcceptInvitationController::class)
    ->name('invitations.accept');
```

The second `#[Authorize]` argument is the route parameter name that holds the model instance.

## Actions Without a Model Instance

When the ability checks against the class rather than an instance (e.g. a "create"-style
action with no bound model), pass the model class:

```php
// Policy
public function start(User $user): bool
{
    return true; // Any authenticated user may attempt to start one
}

// Controller
use App\Models\Order;

class StartOrderController
{
    #[Authorize('start', Order::class)]
    public function __invoke()
    {
        // ...
    }
}
```

## Auto-Discovery

Same as resource policies — follows the `{Model}Policy` naming convention:

- Model: `App\Models\Invitation`
- Policy: `App\Policies\InvitationPolicy`

## Key Points

- Authorize non-CRUD actions with `#[Authorize('ability', 'paramName')]` on the controller method — not `->can()` on the route
- The route file maps URL → controller only; authorization lives on the controller
- Second attribute argument is the route parameter name (e.g. `'invitation'`), or the model class for non-instance checks
- `#[Authorize]` *is* the `can` middleware — never declare the same ability on both the controller and the route
- Delegate to model domain methods (e.g. `$invitation->isInvitee($user)`)
- Same auto-discovery rules as resource policies; can coexist with CRUD methods in the same policy class
