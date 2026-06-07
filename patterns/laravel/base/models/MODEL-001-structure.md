# MODEL-001-structure

## Pattern

Eloquent model structure and conventions.

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Models;

use App\Database\Factories\OrderFactory;
use App\Enums\OrderStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * @property int $id
 * @property string $reference
 * @property int $user_id
 * @property OrderStatus $status
 * @property int $total_cents
 * @property bool $is_paid
 * @property \Carbon\Carbon $created_at
 * @property \Carbon\Carbon $updated_at
 *
 * @property-read User $user
 */
class Order extends Model
{
    /** @use HasFactory<OrderFactory> */
    use HasFactory;

    // Start with empty - only add fields with a clear mass-assignment use case
    protected $fillable = [];

    // Alternative: Use $guarded to protect system fields (less recommended)
    // protected $guarded = ['id', 'user_id'];

    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,  // Enum cast
            'total_cents' => 'integer',
            'is_paid' => 'boolean',
        ];
    }

    protected static function newFactory(): OrderFactory
    {
        return OrderFactory::new();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

## Mass Assignment Security

**Philosophy: Secure by Default.** Prefer security and explicitness over convenience. Empty
`$fillable` prevents future developers from accidentally exposing sensitive fields or bypassing
domain logic.

**Default: Start strict** — empty `$fillable`, add fields only when you have a clear
mass-assignment use case.

```php
// ✅ Start here - explicit and secure
protected $fillable = [];
```

**Only add fields that will be mass-assigned:**

```php
// ✅ GOOD - only fields updated via $model->update($request->validated())
protected $fillable = [
    'reference',   // User can edit
    'notes',       // User can edit
];

// ❌ NEVER include in $fillable:
// - System-assigned fields (user_id, foreign keys)
// - Fields set via domain methods (paid_at, status)
// - Immutable fields (created_at, type)
```

**Alternative: `$guarded` (less recommended)** — an implicit blocklist is insecure by default.
Prefer the explicit allowlist of `$fillable`; when in doubt, use empty `$fillable` plus
explicit assignment.

## Explicit vs Mass Assignment

**For system-assigned fields, assign explicitly** (in an Action, with the current user passed
in from the controller — see the action pattern):

```php
$order = new Order();
$order->reference = $data->reference;
$order->user_id = $user->id;   // Explicit; $user passed into the Action, not pulled from global state
$order->save();
```

**For user-editable fields, mass assignment is safe after validation:**

```php
public function update(UpdateOrderRequest $request, Order $order)
{
    $order->update($request->validated());  // Safe — FormRequest already validated
}
```

## Create-Once Entities

Some entities are **created once and never updated** — only state changes via domain methods.
These should have **empty `$fillable`** (or `$guarded = ['*']`).

**Examples:** invitations (create once, accept/deny via methods), transactions (immutable),
audit records, orders (create once, state changes via place/cancel/fulfill methods).

```php
class Invitation extends Model
{
    protected $fillable = [];  // or $guarded = ['*'];

    /**
     * Domain methods handle all state changes.
     */
    public function accept(): void
    {
        if (! $this->isPending()) {
            throw new InvitationAlreadyProcessedException();
        }

        $this->accepted_at = now();
    }
}
```

**In the Action — explicit assignment for all fields:**

```php
class CreateInvitationAction
{
    public function execute(User $inviter, InvitationData $data): Invitation
    {
        $invitation = new Invitation();
        $invitation->inviter_id = $inviter->id;            // System (from the authenticated user)
        $invitation->type = InvitationType::Standard;      // System (business logic)
        $invitation->target_email = $data->targetEmail;    // User-provided, set once
        $invitation->message = $data->message;             // User-provided, set once
        $invitation->save();

        return $invitation;
    }
}
```

State changes then happen via domain methods, with the Action coordinating persistence and
events:

```php
class AcceptInvitationAction
{
    public function execute(Invitation $invitation): Invitation
    {
        $invitation->accept();  // Domain method sets accepted_at
        $invitation->save();

        event(new InvitationAccepted($invitation->id));

        return $invitation;
    }
}
```

**Empty `$fillable` when:** create-once entities, state-machine entities (updates via domain
methods only), immutable records.

**`$fillable` with fields when:** the entity has an update endpoint and users edit fields after
creation via `Model::create()` / `$model->update()`.

## Common Mistakes

### ❌ Mass assignment for system-controlled data

```php
// ❌ BAD - none of these are edited after creation
protected $fillable = ['inviter_id', 'type', 'target_email', 'message'];
```

**Ask:** "Will users EDIT this field after creation via an update endpoint?" If NO → empty
`$fillable`, explicit assignment. If YES → put it in `$fillable`.

### ❌ Foreign keys in $fillable

```php
// ❌ BAD - foreign keys are ALWAYS system-assigned
protected $fillable = ['user_id', 'parent_id', 'category_id'];
```

A user could manipulate a foreign key to reach another user's data. Assign FKs explicitly in
the Action instead:

```php
protected $fillable = ['reference', 'notes'];  // Only user-editable fields

// In the Action
$order->user_id = $user->id;   // current user passed into the Action
$order->parent_id = $parentId; // from the route
```

## Domain Methods vs Direct Assignment

Models should have **behavior, not just data**. Use domain methods for state transitions and
operations with business logic.

### Use domain methods for state transitions

```php
/**
 * Accept the invitation.
 *
 * @throws InvitationAlreadyProcessedException
 */
public function accept(): void
{
    if (! $this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->accepted_at = now();
}

/**
 * Check if invitation is pending.
 */
public function isPending(): bool
{
    return $this->accepted_at === null
        && $this->denied_at === null;
}
```

**Why:** encapsulates business rules (can't accept twice), self-documenting, enforces
invariants in one place, testable in isolation.

### Use direct assignment for simple data

```php
// ✅ Fine - no business rules
$order->reference = $data->reference;
$order->notes = $data->notes;
```

### Domain methods are pure

No external dependencies — no service location, no request/session/global auth access. Receive
what you need as parameters:

```php
// ❌ BAD - reaches into global state
public function accept(): void
{
    $userId = auth()->id();        // NO - request-scoped global
    $this->accepted_by = $userId;
    $this->accepted_at = now();
}

// ✅ GOOD - pure state transition, receives data as params
public function accept(?int $acceptedBy = null): void
{
    if (! $this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->accepted_at = now();
    $this->accepted_by = $acceptedBy;
}
```

Pure methods are unit-testable without booting Laravel and safe under long-running workers (no
stale references).

### Domain methods don't save

Domain methods **set state but don't persist** — Actions handle saving and side effects:

```php
// ❌ DON'T save in a domain method
public function accept(): void
{
    $this->accepted_at = now();
    $this->save(); // NO - the Action handles this
}

// ✅ DO let the Action persist
public function accept(): void
{
    $this->accepted_at = now();
}
```

Actions coordinate (save, dispatch events, touch multiple models); models own domain logic and
invariants.

### When to use domain methods

**✅ Use when:** a state transition (pending → accepted), business rules apply
(`canBePlaced()`), a domain concept (accept, cancel, activate), or invariants must be enforced.

**❌ Don't use when:** simple data assignment with no business logic.

**❌ Never create traditional setters** — they just wrap assignment with no added value:

```php
// ❌ BAD
public function setName(string $name): void
{
    $this->name = $name;
}
```

## Accessors (Computed Properties)

Use modern `Attribute` accessors for computed values. Document them in PHPDoc to distinguish
from database columns.

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

/**
 * @property int $id
 * @property int $total_cents
 *
 * @property-read int $item_count    // Computed: count of line items
 * @property-read int $balance_cents // Computed: total - paid
 */
class Order extends Model
{
    /**
     * Number of line items on this order.
     */
    protected function itemCount(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->items()->count(),
        );
    }
}
```

### JSON serialization with `$appends`

Include computed properties in API responses automatically:

```php
class Order extends Model
{
    protected $appends = ['item_count', 'balance_cents'];
}
```

### PHPDoc for computed properties

Always document computed properties to distinguish them from database columns:

```php
/**
 * @property int $id                     // Database column
 * @property int $total_cents            // Database column
 *
 * @property-read OrderStatus $status    // Computed from timestamps
 * @property-read int $balance_cents     // Computed: total - paid
 */
```

### Avoid legacy accessor syntax

```php
// ❌ AVOID - old Laravel syntax
public function getItemCountAttribute(): int { return $this->items()->count(); }

// ✅ GOOD - modern Attribute syntax
protected function itemCount(): Attribute
{
    return Attribute::make(get: fn () => $this->items()->count());
}
```

### Caching expensive computations

```php
protected function expensiveCalculation(): Attribute
{
    return Attribute::make(
        get: fn () => $this->performExpensiveCalculation(),
    )->shouldCache();
}
```

## Security Layers

Mass-assignment protection is one layer, not the whole story:

1. **FormRequests** — primary validation (what data is allowed)
2. **Policies** — authorization (who can do what)
3. **`$fillable`/`$guarded`** — mass-assignment protection (prevents accidents)

`$fillable` catches mistakes, but FormRequests are the real security layer.

## What "Thin Models" Means

**Thin does NOT mean anemic** (data bags with no behavior).

**Thin means:**
- Models have domain methods for state transitions and business rules
- Models enforce their own invariants
- Complex orchestration is delegated to Actions (save, dispatch events, coordinate models)
- Complex queries are delegated to Query Builders
- Models focus on their own state and behavior, not coordination

**Examples:**
- ✅ Thin: `$invitation->accept()` — model owns the state transition
- ❌ Fat: `$invitation->acceptAndNotifyUsers()` — too much coordination
- ✅ Thin: `$order->isOwnedBy($user)` — domain query
- ❌ Fat: `$order->transferAndMigrateData($newOwner)` — too complex for a model

## Key Points

- Lives in `app/Models/`
- Use the `HasFactory` trait and implement `newFactory()` to return the typed factory
- **`$fillable`: strict by default** — start empty; only add user-editable fields with a clear
  mass-assignment use case; never put system fields (user_id, foreign keys) in `$fillable`;
  prefer `$fillable` (allowlist) over `$guarded` (blocklist)
- Use the `casts()` method (not the `$casts` property) for type safety
- Use enum casts for status/type/mode fields
- **Use domain methods for state transitions**; use direct assignment for simple data
- **Domain methods are pure and don't save** — Actions handle persistence and events
- **Never create traditional setters**
- Assign the current user explicitly: pass the `User` into the Action and set `user_id` there —
  don't reach for global auth helpers inside the model
- Add PHPDoc `@property` for attributes, `@property-read` for relationships and computed values
- Type-hint relationship return types
- Keep complex query logic in Query Builders
