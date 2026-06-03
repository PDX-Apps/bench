# MODEL-003-domain-methods

## Pattern

Models should have domain methods for state transitions and operations with business logic. This implements true Domain-Driven Design where models have behavior, not just data.

## Why

**Anemic Domain Model is an anti-pattern** (Martin Fowler):
- Models become data bags with no behavior
- Business logic scatters across Actions/Services
- Hard to enforce invariants
- Violates encapsulation

**Rich Domain Models solve this:**
- Models own their state transitions
- Business rules enforced in one place
- Self-documenting (`accept()` vs `accepted_at = now()`)
- Testable in isolation
- True Domain-Driven Design

## When to Use Domain Methods

### ✅ Use Domain Methods For

**1. State Transitions**
```php
public function accept(): void
{
    if (!$this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->accepted_at = now();
}

public function deny(): void
{
    if (!$this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->denied_at = now();
}

public function cancel(): void
{
    if (!$this->canBeCancelled()) {
        throw new CannotCancelException();
    }

    $this->cancelled_at = now();
}
```

**2. Business Operations with Rules**
```php
public function transferOwnership(int $newUserId): void
{
    if ($this->user_id === $newUserId) {
        throw new CannotTransferToSelfException();
    }

    if (!$this->hasMember($newUserId)) {
        throw new NewOwnerNotMemberException();
    }

    $this->user_id = $newUserId;
}

public function promote(UserRole $newRole): void
{
    if (!$this->canBePromoted($newRole)) {
        throw new InvalidPromotionException();
    }

    $this->role = $newRole;
    $this->promoted_at = now();
}
```

**3. Domain Calculations**
```php
public function calculateTotalCost(): Money
{
    return $this->items->sum(fn($item) => $item->total);
}

public function getAvailableSlots(): int
{
    $currentMembers = $this->getCurrentMemberCount();
    $pendingInvitations = $this->getPendingInvitationCount();

    return $this->maximum_members - $currentMembers - $pendingInvitations;
}
```

**4. State Checks with Logic**
```php
public function isPending(): bool
{
    return $this->accepted_at === null
        && $this->denied_at === null;
}

public function canBeAccepted(): bool
{
    return $this->isPending()
        && $this->household->hasAvailableSlots()
        && !$this->isExpired();
}

public function isOwner(User|int $user): bool
{
    $userId = $user instanceof User ? $user->id : $user;

    return $this->user_id === $userId;
}
```

### ❌ Don't Use Domain Methods For

**1. Simple Data Assignment**
```php
// ❌ DON'T - just wrapping assignment
public function setName(string $name): void
{
    $this->name = $name;
}

// ✅ DO - use direct assignment
$household->name = $data->name;
```

**2. No Business Logic**
```php
// ❌ DON'T - no rules, just setting
public function setDescription(string $description): void
{
    $this->description = $description;
}

// ✅ DO - direct assignment is fine
$household->description = $data->description;
```

**3. Traditional Getters**
```php
// ❌ DON'T - use property access
public function getName(): string
{
    return $this->name;
}

// ✅ DO - use property directly
echo $household->name;
```

## Domain Methods Don't Save

**Domain methods set state but don't persist** - Actions handle saving:

```php
// ❌ DON'T save in domain method
public function accept(): void
{
    $this->accepted_at = now();
    $this->save(); // NO - breaks single responsibility
}

// ✅ DO let Action handle persistence
public function accept(): void
{
    $this->accepted_at = now();
    // Action will call save()
}
```

**Why Actions save, not models:**
- Actions coordinate persistence and events
- Models focus on domain logic
- Clear separation of concerns
- Easier testing (no database in model tests)

## Example: Complete State Machine

```php
class HouseholdInvitation extends Model
{
    /**
     * Accept the invitation.
     *
     * @throws InvitationAlreadyProcessedException
     */
    public function accept(): void
    {
        if (!$this->isPending()) {
            throw new InvitationAlreadyProcessedException(
                'Invitation has already been ' . $this->getStatus()->value
            );
        }

        $this->accepted_at = now();
    }

    /**
     * Deny the invitation.
     *
     * @throws InvitationAlreadyProcessedException
     */
    public function deny(): void
    {
        if (!$this->isPending()) {
            throw new InvitationAlreadyProcessedException(
                'Invitation has already been ' . $this->getStatus()->value
            );
        }

        $this->denied_at = now();
    }

    /**
     * Cancel the invitation (by inviter).
     *
     * @throws CannotCancelInvitationException
     */
    public function cancel(): void
    {
        if (!$this->isPending()) {
            throw new CannotCancelInvitationException(
                'Only pending invitations can be cancelled'
            );
        }

        $this->cancelled_at = now();
    }

    /**
     * Check if invitation is pending.
     */
    public function isPending(): bool
    {
        return $this->accepted_at === null
            && $this->denied_at === null
            && $this->cancelled_at === null;
    }

    /**
     * Check if invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return $this->isPending()
            && !$this->isExpired()
            && $this->household->hasAvailableSlots();
    }

    /**
     * Check if invitation has expired.
     */
    public function isExpired(): bool
    {
        return $this->created_at->addDays(7)->isPast();
    }

    /**
     * Get current status as enum.
     */
    public function getStatus(): InvitationStatus
    {
        return match (true) {
            $this->accepted_at !== null => InvitationStatus::Accepted,
            $this->denied_at !== null => InvitationStatus::Denied,
            $this->cancelled_at !== null => InvitationStatus::Cancelled,
            $this->isExpired() => InvitationStatus::Expired,
            default => InvitationStatus::Pending,
        };
    }
}
```

## How Actions Use Domain Methods

```php
class AcceptInvitationAction
{
    public function execute(HouseholdInvitation $invitation): HouseholdInvitation
    {
        // Validate (can involve multiple entities)
        if (!$invitation->canBeAccepted()) {
            throw new CannotAcceptInvitationException(
                'Invitation cannot be accepted at this time'
            );
        }

        // Model handles state transition
        $invitation->accept();

        // Action handles persistence
        $invitation->save();

        // Action handles side effects
        event(new InvitationAccepted(
            invitationId: $invitation->id,
            householdId: $invitation->household_id,
            userId: $invitation->invitee_id,
        ));

        return $invitation->fresh();
    }
}
```

## Testing Domain Methods

Domain methods are easily testable without database:

```php
test('cannot accept already accepted invitation', function () {
    $invitation = new HouseholdInvitation();
    $invitation->accepted_at = now();

    expect(fn() => $invitation->accept())
        ->toThrow(InvitationAlreadyProcessedException::class);
});

test('can accept pending invitation', function () {
    $invitation = new HouseholdInvitation();
    $invitation->created_at = now();

    $invitation->accept();

    expect($invitation->accepted_at)->not->toBeNull();
});

test('invitation expires after 7 days', function () {
    $invitation = new HouseholdInvitation();
    $invitation->created_at = now()->subDays(8);

    expect($invitation->isExpired())->toBeTrue();
    expect($invitation->canBeAccepted())->toBeFalse();
});
```

## Complex Operations: Use Services

When logic gets too complex for a model, extract to a service:

```php
// Model stays clean
class Order extends Model
{
    public function place(): void
    {
        $this->status = OrderStatus::Placed;
        $this->placed_at = now();
    }
}

// Complex validation in service
class OrderPlacementService
{
    public function canPlaceOrder(Order $order): bool
    {
        return $order->status === OrderStatus::Draft
            && !$order->items->isEmpty()
            && $order->total->isGreaterThan(Money::zero())
            && $this->customerHasSufficientCredit($order)
            && $this->allItemsInStock($order);
    }

    private function customerHasSufficientCredit(Order $order): bool
    {
        // Complex credit check logic
    }

    private function allItemsInStock(Order $order): bool
    {
        // Complex inventory check logic
    }
}

// Action coordinates
class PlaceOrderAction
{
    public function __construct(
        private readonly OrderPlacementService $placementService
    ) {}

    public function execute(Order $order): Order
    {
        if (!$this->placementService->canPlaceOrder($order)) {
            throw new CannotPlaceOrderException();
        }

        $order->place();
        $order->save();

        event(new OrderPlaced($order));

        return $order;
    }
}
```

## Naming Conventions

**State Transitions:**
- `accept()`, `deny()`, `cancel()` - Simple verbs
- `activate()`, `suspend()`, `archive()` - Domain actions
- `approve()`, `reject()`, `finalize()` - Business operations

**State Checks:**
- `isPending()`, `isActive()`, `isExpired()` - Boolean checks
- `canBeAccepted()`, `canBeCancelled()` - Permission checks
- `hasAvailableSlots()`, `hasMembers()` - Existence checks

**Calculations:**
- `getAvailableSlots()`, `getTotalCost()` - Get prefix for calculations
- `calculateDiscount()`, `calculateTax()` - Calculate prefix for complex math

**Avoid:**
- Traditional setters: `setName()`, `setStatus()`
- Traditional getters: `getName()`, `getEmail()`
- Vague names: `process()`, `update()`, `handle()`

## Anti-Patterns to Avoid

### ❌ Anemic Domain Model
```php
// ❌ Model has no behavior
class Invitation extends Model
{
    // Just properties, no methods
}

// ❌ Action knows too much about model internals
class AcceptInvitationAction
{
    public function execute(Invitation $invitation): void
    {
        if ($invitation->accepted_at !== null || $invitation->denied_at !== null) {
            throw new Exception();
        }

        $invitation->accepted_at = now();
        $invitation->save();
    }
}
```

### ✅ Rich Domain Model
```php
// ✅ Model has behavior
class Invitation extends Model
{
    public function accept(): void
    {
        if (!$this->isPending()) {
            throw new InvitationAlreadyProcessedException();
        }

        $this->accepted_at = now();
    }

    public function isPending(): bool
    {
        return $this->accepted_at === null && $this->denied_at === null;
    }
}

// ✅ Action delegates to model
class AcceptInvitationAction
{
    public function execute(Invitation $invitation): void
    {
        $invitation->accept();
        $invitation->save();
    }
}
```

### ❌ Saving in Model Methods
```php
// ❌ Model handles persistence
public function accept(): void
{
    $this->accepted_at = now();
    $this->save(); // NO
    event(new InvitationAccepted($this)); // NO
}
```

### ✅ Separation of Concerns
```php
// ✅ Model handles state
public function accept(): void
{
    $this->accepted_at = now();
}

// ✅ Action handles persistence and events
public function execute(Invitation $invitation): void
{
    $invitation->accept();
    $invitation->save();
    event(new InvitationAccepted($invitation));
}
```

## Benefits

1. **Encapsulation**: Model controls its state changes
2. **Single Responsibility**: Models have domain logic, Actions have orchestration
3. **Testability**: Test domain methods without database
4. **Discoverability**: IDE shows available operations
5. **Maintainability**: Rules in one place, not scattered
6. **Refactor-Safety**: Change internals without breaking callers
7. **Self-Documenting**: `accept()` vs `accepted_at = now()`
8. **True DDD**: Models are not anemic data bags

## Related

- `MODEL-001-structure` - Model configuration and conventions
- `SERVICE-001-actions` - Actions call domain methods
- `ADR-001-modular-architecture` - DDD principles
