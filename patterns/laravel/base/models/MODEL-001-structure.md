# MODEL-001-structure

## Pattern

Eloquent model structure and conventions.

## Dependencies

- `CODE-003-enums` - Use enums for status/type/mode fields
- `database/DB-002-factories.md` - Model factories for testing
- `database/DB-003-seeders.md` - Database seeders

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use App\Models\User;
use Modules\Household\Database\Factories\HouseholdFactory;

/**
 * @property int $id
 * @property string $name
 * @property int $user_id
 * @property int $max_members
 * @property bool $is_active
 * @property \Carbon\Carbon $created_at
 * @property \Carbon\Carbon $updated_at
 *
 * @property-read User $user
 */
class Household extends Model
{
    /** @use HasFactory<HouseholdFactory> */
    use HasFactory;

    // Start with empty - only add fields with a clear mass-assignment use case
    protected $fillable = [];

    // Alternative: Use $guarded to protect system fields (less recommended)
    // protected $guarded = ['id', 'public_id', 'user_id', 'code'];

    protected function casts(): array
    {
        return [
            'status' => HouseholdStatus::class,  // Enum cast (see CODE-003-enums)
            'max_members' => 'integer',
            'is_active' => 'boolean',
        ];
    }

    protected static function newFactory(): HouseholdFactory
    {
        return HouseholdFactory::new();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

## Mass Assignment Security

**Philosophy: Secure by Default**

We prioritize security and explicitness over convenience. This project is built for scale, multiple teams, and long-term maintenance. Empty `$fillable` prevents future developers from accidentally exposing sensitive fields or bypassing domain logic.

**Default: Start Strict**

Start with **empty `$fillable`** and only add fields when you have a clear use case for mass assignment.

```php
// ✅ Start here - explicit and secure
protected $fillable = [];
```

**Only add fields that will be mass-assigned:**

```php
// ✅ GOOD - only fields updated via $model->update($request->validated())
protected $fillable = [
    'name',        // User can edit
    'description', // User can edit
];

// ❌ NEVER include in $fillable:
// - System-assigned fields (user_id, foreign keys)
// - Auto-generated fields (public_id, code)
// - Fields set via domain methods (accepted_at, status)
// - Immutable fields (created_at, type)
```

**Alternative: Use `$guarded` (Less Recommended)**

```php
// ⚠️ RISKY - everything except these is fillable
protected $guarded = [
    'id',
    'public_id',
    'user_id',
    'code',
];
```

**Recommendation:**
- ✅ **Prefer `$fillable`** - Explicit allowlist (secure by default)
- ❌ **Avoid `$guarded`** - Implicit blocklist (insecure by default)
- ✅ **When in doubt** - Use empty `$fillable` and explicit assignment

## Explicit vs Mass Assignment

**For system-assigned fields, use explicit assignment:**

```php
// ✅ Secure - explicit ownership assignment (in Action)
$entity = new Entity();
$entity->name = $data->name;
$entity->user_id = $this->auth->userId();  // Explicit, not mass-assigned (AuthService)
$entity->save();
```

**For user-editable fields, mass assignment is safe:**

```php
// ✅ Safe - FormRequest already validated
public function update(UpdateEntityRequest $request, Entity $entity)
{
    $entity->update($request->validated());  // Safe with validation
}
```

## Create-Once Entities

Some entities are **created once and never updated** - only state changes via domain methods. These should have **empty $fillable** or `$guarded = ['*']`.

**Examples:**
- Invitations (create once, accept/deny via methods)
- Transactions (create once, never edited)
- Audit logs (create once, immutable)
- Orders (create once, state changes via place/cancel/fulfill methods)

### Pattern

```php
class Invitation extends Model
{
    // Option 1: Empty $fillable (explicit)
    protected $fillable = [];

    // Option 2: Guard everything (explicit)
    // protected $guarded = ['*'];

    /**
     * Domain methods handle all state changes.
     */
    public function accept(): void
    {
        if (!$this->isPending()) {
            throw new InvitationAlreadyProcessedException();
        }

        $this->accepted_at = now();
    }
}
```

**In Action - Explicit assignment for all fields:**

```php
class CreateInvitationAction
{
    public function __construct(
        private readonly AuthService $auth
    ) {}

    public function execute(InvitationData $data): Invitation
    {
        $invitation = new Invitation();
        $invitation->entity_id = $data->entityId;         // System
        $invitation->inviter_id = $this->auth->userId();  // System (AuthService)
        $invitation->type = InvitationType::Invitation;   // System (business logic)
        $invitation->target_id = $data->targetId;         // User-provided, but set once
        $invitation->target_email = $data->targetEmail;   // User-provided, but set once
        $invitation->message = $data->message;            // User-provided, but set once
        $invitation->save();

        return $invitation;
    }
}
```

**State changes via domain methods:**

```php
class AcceptInvitationAction
{
    public function execute(Invitation $invitation): Invitation
    {
        $invitation->accept();  // Domain method sets accepted_at
        $invitation->save();

        event(new InvitationAccepted($invitation));

        return $invitation;
    }
}
```

**When to use empty $fillable:**
- ✅ Create-once entities (no update endpoint)
- ✅ State machine entities (updates via domain methods only)
- ✅ All fields set at creation, never changed
- ✅ Immutable entities (audit logs, transactions)

**When to use $fillable with fields:**
- ✅ Entities with update endpoints
- ✅ Fields users can edit after creation
- ✅ Using `Model::create()` or `$entity->update()` with user data

## Common Mistakes

### ❌ Mass Assignment for System-Controlled Data

```php
// ❌ BAD - fields are never edited after creation
class Invitation extends Model
{
    protected $fillable = [
        'entity_id',      // System - from route
        'inviter_id',     // System - from auth
        'type',           // System - business logic
        'target_id',      // Set once at creation
        'target_email',   // Set once at creation
        'message',        // Set once at creation
    ];
}
```

**Problem:** None of these fields are ever updated after creation. Having them in `$fillable` creates security risks (mass assignment vulnerabilities) with no benefit.

**Ask yourself:** "Will users EDIT this field after creation via an update endpoint?"
- If NO → Empty $fillable, explicit assignment
- If YES → Put in $fillable

```php
// ✅ GOOD - explicit assignment, no mass assignment
class Invitation extends Model
{
    protected $fillable = [];  // Or $guarded = ['*'];
}

// In Action - explicit assignment
$invitation = new Invitation();
$invitation->entity_id = $entityId;
$invitation->inviter_id = $this->auth->userId();
$invitation->type = InvitationType::Invitation;
$invitation->target_id = $data->targetId;
$invitation->target_email = $data->targetEmail;
$invitation->message = $data->message;
$invitation->save();
```

### ❌ Foreign Keys in $fillable

```php
// ❌ BAD - foreign keys are ALWAYS system-assigned
protected $fillable = [
    'user_id',     // NO - from auth
    'parent_id',   // NO - from route
    'category_id', // NO - from route
];
```

**Security risk:** User could manipulate foreign keys to access other users' data.

```php
// ✅ GOOD - explicit assignment
protected $fillable = ['name', 'description'];  // Only user-editable fields

// In Action
$entity->user_id = $this->auth->userId();  // Explicit
$entity->parent_id = $parentId;            // Explicit
$entity->name = $data->name;               // User-editable
```

### ❌ Using auth()->id()

```php
// ❌ BAD - returns mixed, causes type errors
$entity->user_id = auth()->id();
```

```php
// ✅ GOOD - use AuthService
$entity->user_id = $this->auth->userId();  // Returns int, type-safe
```

## Domain Methods vs Direct Assignment

Models should have **behavior, not just data**. Use domain methods for state transitions and operations with business logic.

### Use Domain Methods For State Transitions

**State transitions are domain operations** that represent meaningful business concepts:

```php
/**
 * Accept the invitation.
 *
 * @throws InvitationAlreadyProcessedException
 */
public function accept(): void
{
    if (!$this->isPending()) {
        throw new InvitationAlreadyProcessedException();
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
        throw new InvitationAlreadyProcessedException();
    }

    $this->denied_at = now();
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

**Why domain methods:**
- ✅ Encapsulate business rules (can't accept twice)
- ✅ Self-documenting (`accept()` vs `accepted_at = now()`)
- ✅ Enforce invariants in one place
- ✅ Easy to add side effects later
- ✅ Testable in isolation
- ✅ True Domain-Driven Design

### Use Direct Assignment For Simple Data

**Simple data with no business logic** can use direct property assignment:

```php
// ✅ Fine - no business rules
$household->name = $data->name;
$household->description = $data->description;

// ✅ Also fine in Actions - system-assigned fields
$household->user_id = $this->auth->userId();
```

### Domain Methods Are Pure

Domain methods should be **pure** - no external dependencies:

```php
// ❌ BAD - calling external service
public function accept(): void
{
    $notifier = app(NotificationService::class);  // NO - service location
    $notifier->send(...);
    $this->accepted_at = now();
}

// ❌ BAD - accessing request/session
public function accept(): void
{
    $userId = auth()->id();  // NO - request-scoped
    $this->accepted_by = $userId;
    $this->accepted_at = now();
}

// ✅ GOOD - pure state transition, receives data as params
public function accept(?int $acceptedBy = null): void
{
    if (!$this->isPending()) {
        throw new InvitationAlreadyProcessedException();
    }

    $this->accepted_at = now();
    $this->accepted_by = $acceptedBy;
}
```

**Why pure:**
- Unit testable without Laravel boot
- Octane-safe (no stale references)
- Clear separation: models own state, Actions coordinate

### Domain Methods Don't Save

Domain methods **set state but don't save** - persistence is handled by Actions:

```php
// ❌ DON'T save in domain method
public function accept(): void
{
    $this->accepted_at = now();
    $this->save(); // NO - Action handles this
}

// ✅ DO let Action handle persistence
public function accept(): void
{
    $this->accepted_at = now();
    // No save - Action will call save()
}
```

**Why Actions save, not models:**
- Actions coordinate multiple operations (save, dispatch events, coordinate models)
- Models focus on domain logic and invariants
- Clear separation: domain logic (model) vs application flow (Action)

### When to Use Domain Methods

**✅ Use domain methods when:**
- State transition (pending → accepted, active → suspended)
- Business rules apply (`canBePlaced()`, `isEligible()`)
- Domain concept (accept, deny, approve, cancel, activate, suspend)
- Invariants must be enforced (can't accept denied invitation)

**❌ Don't use domain methods when:**
- Simple data assignment (name, description, notes)
- No business logic required
- Just setting a value from user input

**❌ Never create traditional setters:**
```php
// ❌ BAD - just wrapping assignment, no value
public function setName(string $name): void
{
    $this->name = $name;
}
```

### Example: Complex Domain Operation

```php
/**
 * Transfer ownership to another user.
 *
 * @throws CannotTransferToSelfException
 * @throws NewOwnerNotMemberException
 */
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
```

See `MODEL-003-domain-methods` for comprehensive guidance.

## Accessors (Computed Properties)

Use modern `Attribute` accessors for computed values. Document them in PHPDoc to distinguish from database columns.

### Modern Accessor Syntax

```php
use Illuminate\Database\Eloquent\Casts\Attribute;

/**
 * @property int $id
 * @property string $name
 * @property int $user_id
 *
 * @property-read int $maximum_members      // Computed: membership plan limit
 * @property-read int $current_member_count // Computed: count of members
 * @property-read int $available_slots      // Computed: max - current
 */
class Household extends Model
{
    /**
     * Maximum members allowed (from membership plan).
     */
    protected function maximumMembers(): Attribute
    {
        return Attribute::make(
            get: fn () => 5, // TODO: Replace with membership plan lookup
        );
    }

    /**
     * Current number of members in this household.
     */
    protected function currentMemberCount(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->members()->count(),
        );
    }

    /**
     * Available invitation slots.
     */
    protected function availableSlots(): Attribute
    {
        return Attribute::make(
            get: fn () => $this->maximum_members - $this->current_member_count,
        );
    }
}
```

### JSON Serialization with `$appends`

Include computed properties in API responses automatically:

```php
class Household extends Model
{
    // These computed properties will be included in JSON output
    protected $appends = [
        'maximum_members',
        'current_member_count',
        'available_slots',
    ];
}
```

Then `HouseholdResource` or `response()->json($household)` automatically includes:
```json
{
    "id": 1,
    "name": "Smith Family",
    "maximum_members": 5,
    "current_member_count": 2,
    "available_slots": 3
}
```

### PHPDoc for Computed Properties

Always document computed properties with a comment to distinguish from database columns:

```php
/**
 * @property int $id                        // Database column
 * @property string $name                   // Database column
 *
 * @property-read InvitationStatus $status  // Computed from accepted_at/denied_at
 * @property-read int $available_slots      // Computed: max - current
 */
```

### Avoid Legacy Syntax

```php
// ❌ AVOID - old Laravel syntax, no longer recommended
public function getMaximumMembersAttribute(): int
{
    return 5;
}

// ✅ GOOD - modern Attribute syntax
protected function maximumMembers(): Attribute
{
    return Attribute::make(get: fn () => 5);
}
```

### Caching Expensive Computations

For computationally intensive accessors:

```php
protected function expensiveCalculation(): Attribute
{
    return Attribute::make(
        get: fn () => $this->performExpensiveCalculation(),
    )->shouldCache();
}
```

## Security Layers

Laravel security is layered, not just `$fillable`:

1. **FormRequests** - Primary validation (what data is allowed)
2. **Policies** - Authorization (who can do what)
3. **$fillable/$guarded** - Mass assignment protection (prevents accidents)

`$fillable` catches mistakes, but FormRequests are the real security layer.

## Key Points

- Lives in `Modules/{Module}/Models/`
- Use `HasFactory` trait
- **$fillable: Strict by default**
  - **Start with empty `$fillable = []`** (most secure)
  - Only add fields with clear mass-assignment use case
  - User-editable fields via update endpoint → add to $fillable
  - Create-once entities / immutable records → keep empty
  - System fields (user_id, foreign keys) → NEVER in $fillable
  - **Prefer `$fillable` over `$guarded`** (allowlist vs blocklist)
- Use `casts()` method (not `$casts` property) for type safety
- Use enum casts for status/type/mode fields (see CODE-003-enums)
- **Use domain methods for state transitions** (accept, deny, activate, suspend)
- **Use direct assignment for simple data** (name, description)
- **Domain methods don't save** - Actions handle persistence
- **Never create traditional setters** - use domain methods or direct assignment
- **Use AuthService for user_id** - never `auth()->id()` (causes type errors)
- Add PHPDoc with `@property` for attributes, `@property-read` for relationships
- Type-hint relationship return types
- Implement `newFactory()` to return typed factory
- Models have behavior (domain methods) but delegate complex orchestration to Actions
- Keep models focused - move complex queries to Query Builders (see MODEL-002)
- See MODEL-003-domain-methods for comprehensive domain method patterns

## What "Thin Models" Means

**Thin does NOT mean anemic** (data bags with no behavior).

**Thin means:**
- ✅ Models have domain methods for state transitions and business rules
- ✅ Models enforce their own invariants
- ✅ Complex orchestration delegated to Actions (save, dispatch events, coordinate multiple models)
- ✅ Complex queries delegated to Query Builders
- ✅ Models focus on their own state and behavior, not coordination

**Examples:**
- ✅ Thin: `$invitation->accept()` - model owns state transition
- ❌ Fat: `$invitation->acceptAndNotifyUsers()` - too much coordination
- ✅ Thin: `$household->isOwner($user)` - domain query
- ❌ Fat: `$household->transferOwnershipAndMigrateData($newOwner)` - too complex for model
