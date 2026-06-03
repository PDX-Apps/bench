# CODE-003-enums

## Pattern

Use PHP 8.1 backed enums for status fields, types, and modes instead of string constants or getter methods.

## Why

- **Type safety:** Impossible to use invalid values
- **IDE autocomplete:** See all possible values
- **Refactoring:** Rename/remove cases safely
- **Self-documenting:** All values in one place
- **Database efficient:** Store as string, work with typed objects

## When to Use Enums

Use enums for:
- ✅ Status fields (pending, accepted, denied, active, inactive)
- ✅ Type fields (admin, member, guest)
- ✅ Mode fields (email, sms, push)
- ✅ Fixed sets of values (small, medium, large)

Don't use enums for:
- ❌ Dynamic values from database (user roles, categories)
- ❌ Large sets of values (country codes - use database)
- ❌ Values that change frequently

## Dependencies

- `DB-001-migrations` - Enum vs string column decision for database schema

## Implementation

### 1. Create Enum

```php
<?php

namespace Modules\Household\Enums;

enum InvitationStatus: string
{
    /** Invitation sent, awaiting response */
    case Pending = 'pending';

    /** User accepted the invitation */
    case Accepted = 'accepted';

    /** User or owner denied the invitation */
    case Denied = 'denied';

    /**
     * Get a human-readable label.
     */
    public function label(): string
    {
        return match ($this) {
            self::Pending => 'Pending',
            self::Accepted => 'Accepted',
            self::Denied => 'Denied',
        };
    }

    /**
     * Check if an invitation can be accepted.
     */
    public function canBeAccepted(): bool
    {
        return $this === self::Pending;
    }

    /**
     * Get color for UI display.
     */
    public function color(): string
    {
        return match ($this) {
            self::Pending => 'yellow',
            self::Accepted => 'green',
            self::Denied => 'red',
        };
    }
}
```

### 2. Use Cast on Model

```php
use Modules\Household\Enums\InvitationStatus;

class HouseholdInvitation extends Model
{
    protected $casts = [
        'status' => InvitationStatus::class,
    ];
}
```

### 3. Use in Code

```php
// Create with enum (explicit assignment - no mass assignment)
$invitation = new HouseholdInvitation();
$invitation->status = InvitationStatus::Pending;
$invitation->save();

// Access as enum
if ($invitation->status === InvitationStatus::Pending) {
    $invitation->status = InvitationStatus::Accepted;
    $invitation->save();
}

// Use enum methods
$color = $invitation->status->color(); // 'yellow'
$label = $invitation->status->label(); // 'Pending'

// Query with enum
$pending = HouseholdInvitation::where('status', InvitationStatus::Pending)->get();

// Get all cases
$allStatuses = InvitationStatus::cases();

// Get value for database/API
$value = $invitation->status->value; // 'pending'
```

## Anti-Patterns

### ❌ Don't use getter methods

```php
// ❌ BAD - string values, no type safety
class HouseholdInvitation extends Model
{
    public function getStatus(): string
    {
        if ($this->accepted_at !== null) {
            return 'accepted';
        }

        if ($this->denied_at !== null) {
            return 'denied';
        }

        return 'pending';
    }
}

// Usage - prone to typos, no autocomplete
if ($invitation->getStatus() === 'accepted') { // typo: 'aceptted'
    //
}
```

### ✅ Do use enums with the database column

```php
// ✅ GOOD - type safe, autocomplete, single source of truth
class HouseholdInvitation extends Model
{
    protected $casts = [
        'status' => InvitationStatus::class,
    ];
}

// Usage - type safe, autocomplete works
if ($invitation->status === InvitationStatus::Accepted) {
    //
}
```

### ❌ Don't use string constants

```php
// ❌ BAD - scattered constants, easy to misuse
class HouseholdInvitation extends Model
{
    public const STATUS_PENDING = 'pending';
    public const STATUS_ACCEPTED = 'accepted';
    public const STATUS_DENIED = 'denied';
}

// Usage - still strings, no IDE help
$invitation->status = HouseholdInvitation::STATUS_ACCEPTED;
```

### ✅ Do use enums

```php
// ✅ GOOD - all cases in one place, type safe, documented
enum InvitationStatus: string
{
    /** Invitation sent, awaiting response */
    case Pending = 'pending';

    /** User accepted the invitation */
    case Accepted = 'accepted';

    /** User or owner denied the invitation */
    case Denied = 'denied';
}

// Usage - enum instance, type safe
$invitation->status = InvitationStatus::Accepted;
```

## Migration Pattern

### New Tables

Choose between `$table->enum()` and `$table->string()` (see DB-001-migrations for detailed guidance):

```php
use Modules\Household\Enums\InvitationType;

// ✅ Use enum column for stable values on small-medium tables
$types = array_map(fn($case) => $case->value, InvitationType::cases());
$table->enum('type', $types);

// ✅ Use string column for large tables or frequently changing values
$table->string('status', 20)->index();
```

### Converting Existing Columns

When converting existing string columns to enum casts:

```php
// No database change needed - enums use the existing string column
Schema::table('household_invitations', function (Blueprint $table) {
    // Column already exists as string - just add enum cast to the model
    // If column is $table->string(), keep it that way
    // Only use $table->enum() for new tables with stable values
});
```

## OpenAPI Documentation

Enums automatically document possible values in Swagger:

```php
use OpenApi\Attributes as OA;

#[OA\Schema(
    schema: 'HouseholdInvitation',
    properties: [
        new OA\Property(
            property: 'status',
            type: 'string',
            enum: ['pending', 'accepted', 'denied'],
            example: 'pending'
        ),
    ]
)]
class HouseholdInvitation extends Model
{
    //
}
```

## Validation

**ALWAYS use enums in validation** - never hardcode string values.

### ❌ Don't use string validation

```php
// ❌ BAD - hardcoded strings, can get out of sync with enum
class UpdateInvitationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['required', 'in:pending,accepted,denied'],
        ];
    }
}
```

### ✅ Do use enum validation

```php
use Illuminate\Validation\Rules\Enum;

// ✅ GOOD - type safe, single source of truth
class UpdateInvitationRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'status' => ['required', new Enum(InvitationStatus::class)],
        ];
    }
}
```

### Custom validation for complex logic

If validation needs more than just checking valid enum values, use a custom rule:

```php
use Illuminate\Contracts\Validation\ValidationRule;

// For complex validation beyond enum values
class ValidInvitationStatusTransition implements ValidationRule
{
    public function __construct(private InvitationStatus $currentStatus) {}

    public function validate(string $attribute, mixed $value, Closure $fail): void
    {
        if (!$value instanceof InvitationStatus) {
            $fail('Invalid status value');
            return;
        }

        // Custom business logic
        if ($this->currentStatus === InvitationStatus::Accepted && $value !== InvitationStatus::Accepted) {
            $fail('Cannot change status after acceptance');
        }
    }
}
```

### DTO Validation

Use enums in DTO validation too (e.g., Spatie Laravel Data):

```php
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\Validation\Enum as EnumRule;

class InvitationData extends Data
{
    public function __construct(
        #[EnumRule(InvitationStatus::class)]
        public InvitationStatus $status,
    ) {}
}
```

## Naming Conventions

- Enum names: Singular noun (InvitationStatus, UserRole, NotificationType)
- Cases: PascalCase (Pending, Accepted, SuperAdmin)
- Values: snake_case matching database (pending, accepted, super_admin)
- File location: `Modules/{Module}/Enums/{EnumName}.php`
- Docblocks: Add single-line docblock to each case explaining domain context

```php
enum InvitationStatus: string
{
    /** Invitation sent, awaiting response */
    case Pending = 'pending';

    /** User accepted the invitation */
    case Accepted = 'accepted';
}
```

## Examples

**User Role:**
```php
enum UserRole: string
{
    /** Full system access, can manage users and settings */
    case Admin = 'admin';

    /** Standard user with limited permissions */
    case Member = 'member';

    /** Read-only access, cannot modify data */
    case Guest = 'guest';

    public function canManageUsers(): bool
    {
        return $this === self::Admin;
    }
}
```

**Notification Type:**
```php
enum NotificationType: string
{
    /** Send notification via email */
    case Email = 'email';

    /** Send notification via SMS text message */
    case SMS = 'sms';

    /** Send notification via mobile push notification */
    case Push = 'push';

    public function icon(): string
    {
        return match ($this) {
            self::Email => 'envelope',
            self::SMS => 'message',
            self::Push => 'bell',
        };
    }
}
```

## Benefits

1. **Type Safety:** Can't pass invalid value
2. **Autocomplete:** IDE shows all cases
3. **Refactoring:** Rename case updates all usages
4. **Self-Documenting:** All values visible in enum
5. **Behavior:** Add methods to enum (label(), color(), canX())
6. **No Magic Strings:** Eliminate string typos

## Related

- `MODEL-001-structure` - Model configuration and casts
- `DB-001-migrations` - Enum vs string column decision
- `HTTP-002-form-requests` - Use new Enum() in validation
- `CODE-002-swagger` - API documentation with enum values
