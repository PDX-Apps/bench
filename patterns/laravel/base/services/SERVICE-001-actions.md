# SERVICE-001-actions

## Pattern

Single-purpose business operations. One action, one responsibility.

## Dependencies

- `AUTH-003-auth-service` - Use AuthService for authenticated user access
- `MODEL-001-structure` - Models have domain methods for state transitions
- `MODEL-003-domain-methods` - Domain method patterns

## Structure

Actions orchestrate domain operations - models own their state, Actions handle persistence and side effects.

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Actions;

use App\Services\AuthService;
use Modules\Household\Data\InvitationData;
use Modules\Household\Models\HouseholdInvitation;
use Modules\Household\Events\InvitationAccepted;

class AcceptInvitationAction
{
    public function __construct(
        private readonly AuthService $auth
    ) {}

    public function execute(HouseholdInvitation $invitation): HouseholdInvitation
    {
        // Model enforces business rules and state transition
        $invitation->accept();

        // Action handles persistence
        $invitation->save();

        // Action handles side effects (events)
        event(new InvitationAccepted(
            invitationId: $invitation->id,
            householdId: $invitation->household_id,
            userId: $this->auth->userId(),
        ));

        return $invitation->fresh();
    }
}
```

**Pattern:**
- Model method handles state transition: `$invitation->accept()`
- Action handles save: `$invitation->save()`
- Action handles events: `event(new InvitationAccepted(...))`

## Models vs Actions: Division of Responsibilities

**Models handle:**
- ✅ State transitions (`accept()`, `deny()`, `activate()`)
- ✅ Business rule enforcement (can't accept twice)
- ✅ Invariant protection (state consistency)
- ✅ Domain queries (`isPending()`, `isOwner()`)
- ✅ Derived calculations (`getAvailableSlots()`)

**Actions handle:**
- ✅ Persistence (`save()`)
- ✅ Event dispatching (`event(...)`)
- ✅ Coordinating multiple models
- ✅ External service calls
- ✅ Complex validation across entities
- ✅ Transaction management

**Example:**
```php
// Model: Owns its state
public function accept(): void
{
    if (!$this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->accepted_at = now();
}

// Action: Orchestrates the operation
public function execute(HouseholdInvitation $invitation): HouseholdInvitation
{
    $invitation->accept();  // Model enforces rules
    $invitation->save();     // Action persists

    event(new InvitationAccepted(...));  // Action dispatches events

    return $invitation;
}
```

## Usage

```php
// In controller
public function store(
    CreateHouseholdRequest $request,
    CreateHouseholdAction $action
): JsonResponse {
    $household = $action->execute($request->toData());

    return response()->json([
        'data' => new HouseholdResource($household),
    ], 201);
}

// In job
public function handle(CreateHouseholdAction $action): void
{
    $data = HouseholdData::fromInput($this->payload);
    $action->execute($data);
}
```

## Actions Calling Other Actions

```php
class CreateHouseholdWithMembersAction
{
    public function __construct(
        private readonly CreateHouseholdAction $createHousehold,
        private readonly AddMemberAction $addMember,
    ) {}

    public function execute(
        HouseholdData $householdData,
        array $memberData
    ): Household {
        $household = $this->createHousehold->execute($householdData);

        foreach ($memberData as $member) {
            $this->addMember->execute($household, $member);
        }

        return $household;
    }
}
```

## Stateless & Octane-Safe Design

Actions must be **stateless** to support Laravel Octane and enable fast unit testing.

### Rules

1. **No request-scoped dependencies in constructor** - Don't inject Session, Request, or other per-request state
2. **No service location** - Don't use `app()`, `resolve()`, or container helpers
3. **Receive data as parameters** - Pass request data to `execute()`, don't pull from session/request
4. **Constructor injection only for stateless services** - AuthService, other Actions, pure Services

### Why

```php
// ❌ BAD - Request-scoped dependency, breaks Octane
class CartAction
{
    public function __construct(
        private readonly SessionManager $session, // Stale across requests!
    ) {}
}

// ❌ BAD - Service location, can't unit test without Laravel boot
class CartAction
{
    public function execute(): void
    {
        $session = app('session'); // Requires container
    }
}

// ✅ GOOD - Stateless, receives data as params
class CartAction
{
    public function __construct(
        private readonly PricingService $pricing, // Stateless service OK
    ) {}

    public function execute(array $cartItems, CartItemData $newItem): CartResult
    {
        // Pure business logic
    }
}
```

### Request-Scoped Data Flow

Keep request-scoped concerns at the HTTP boundary (Controllers):

```php
// Controller handles request-scoped data
public function store(
    AddToCartRequest $request,
    AddToCartAction $action,
): JsonResponse {
    // Controller reads from session
    $cartItems = $request->session()->get('cart', []);

    // Action receives data as params (stateless)
    $result = $action->execute($cartItems, $request->toData());

    // Controller writes to session
    $request->session()->put('cart', $result->items);

    return response()->json($result);
}
```

### Dependency Injection Safety

| Dependency Type | Inject in Constructor? | Reason |
|-----------------|----------------------|--------|
| AuthService | ✅ Yes | Designed to be request-aware safely |
| Other Actions | ✅ Yes | Stateless |
| Pure Services (calculators, validators) | ✅ Yes | Stateless |
| Session/SessionManager | ❌ No | Request-scoped, stale in Octane |
| Request | ❌ No | Request-scoped |
| Cache (with user keys) | ⚠️ Caution | Pass cache key as param instead |

## Key Points

- Lives in `Modules/{Module}/Actions/`
- Name pattern: `{Verb}{Noun}Action` (Create, Update, Delete, Process, Send)
- Single `execute()` method with clear purpose
- Type-hint parameters and return types
- Inject dependencies via constructor (AuthService, other Actions, Services)
- Use `private readonly` for injected dependencies (ensures immutability)
- Use AuthService for authenticated user access (see AUTH-003-auth-service)
- **Call domain methods on models** - don't directly manipulate state
- **Handle persistence** - call `save()` after domain methods
- **Dispatch events** - coordinate side effects
- **Stateless design** - no request-scoped dependencies, receive data as params
- Can call other Actions
- Testable in isolation (no Laravel boot needed)
- Orchestrate complex operations - models own their state, Actions coordinate

## When to Use Actions

**Use Actions for:**
- Complex business operations
- Operations reused across controllers/jobs/commands
- Multi-step processes
- Operations that need testing in isolation
- When you want a single-responsibility principle

**Skip Actions for:**
- Simple CRUD (just use model methods)
- Trivial operations
- One-line operations
