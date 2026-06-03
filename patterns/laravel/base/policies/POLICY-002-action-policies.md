# POLICY-002-action-policies

## Pattern

Authorization policies for non-CRUD actions (accept, deny, invite, join, etc.).

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Policies;

use App\Models\User;
use Modules\Household\Models\HouseholdInvitation;

class HouseholdInvitationPolicy
{
    public function accept(User $user, HouseholdInvitation $invitation): bool
    {
        return $invitation->isInvitee($user);
    }

    public function deny(User $user, HouseholdInvitation $invitation): bool
    {
        return $invitation->isInvitee($user);
    }

    public function revoke(User $user, HouseholdInvitation $invitation): bool
    {
        return $invitation->isHouseholdOwner($user);
    }
}
```

## Usage in Routes

Use `->can()` directly on the route definition (see `HTTP-004-routes`):

```php
Route::post('invitations/{invitation}/accept', [InvitationResponseController::class, 'accept'])
    ->name('invitations.accept')
    ->can('accept', 'invitation');

Route::post('invitations/{invitation}/deny', [InvitationResponseController::class, 'deny'])
    ->name('invitations.deny')
    ->can('deny', 'invitation');

Route::delete('invitations/{invitation}', [InvitationResponseController::class, 'destroy'])
    ->name('invitations.destroy')
    ->can('revoke', 'invitation');
```

The second parameter to `->can()` is the route parameter name that contains the model.

## Actions Without a Model Instance

For actions that don't have a model instance (e.g., `join` checks against the class, not an instance):

```php
// Policy
public function join(User $user): bool
{
    return true; // Any authenticated user can attempt to join
}

// Route
Route::post('households/join', [HouseholdMembershipController::class, 'join'])
    ->name('households.join')
    ->can('join', Household::class);
```

## Auto-Discovery

Same as resource policies - follows `{Model}Policy` naming convention:

- Model: `Modules\Household\Models\HouseholdInvitation`
- Policy: `Modules\Household\Policies\HouseholdInvitationPolicy`

## Key Points

- Use `->can()` on route definitions, not in controllers
- Second parameter is the route parameter name (e.g., `'invitation'`) or the class for non-instance checks
- Delegate to model domain methods (e.g., `$invitation->isInvitee($user)`)
- Same auto-discovery rules as resource policies
- Can coexist with resource methods in the same policy class
