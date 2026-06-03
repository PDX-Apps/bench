# DATA-002-deletion-and-retention

## Pattern

Soft delete and orchestrated retention for all data with compliance-driven archival processes.

## Core Philosophy

**Keep Everything, Delete Rarely:**
- Soft delete is the default for ALL entities (users, households, budgets, transactions, etc.)
- Data is valuable for analytics, insights, and data warehouse operations
- Deletion is orchestrated, not instant - compliance gives us time
- Hard delete only when legally required or explicitly necessary

## Default: Soft Delete for Everything

### Migration Pattern

```php
Schema::create('table_name', function (Blueprint $table) {
    $table->id();
    // ... other columns
    $table->softDeletes();  // Always include
});
```

### Model Pattern

```php
use Illuminate\Database\Eloquent\SoftDeletes;

class Entity extends Model
{
    use SoftDeletes;

    // Queries automatically exclude soft-deleted records
}
```

### Standard Deletion

```php
// Soft delete (standard delete) - marks deleted_at
$entity->delete();

// Query automatically excludes soft-deleted
Entity::where('user_id', $userId)->get(); // No deleted records

// Access soft-deleted (admin/analytics only)
Entity::withTrashed()->find($id);
Entity::onlyTrashed()->get();
```

## No Cascade Delete or Set Null

**Deprecated Patterns:**
- ❌ `->cascadeOnDelete()` - Never use
- ❌ `->nullOnDelete()` - Never use
- ❌ Database-level CASCADE or SET NULL - Never use

**Why:**
- Loss of data for analytics and audit trails
- Cannot recover from accidents
- Prevents data warehouse utilization
- No control over deletion process

### Foreign Key Pattern

```php
Schema::create('table_name', function (Blueprint $table) {
    $table->id();

    // Foreign key WITHOUT cascade or set null
    $table->foreignId('user_id')
        ->constrained();  // Reference integrity only

    $table->softDeletes();
});
```

### Handling Deleted Parent Records

When a parent is soft-deleted, children remain intact:

```php
// User soft-deleted, but their households remain
$user->delete(); // Soft delete

// Households still exist with reference to soft-deleted user
Household::where('user_id', $user->id)->count(); // Still there

// Access through trashed parent if needed
$user = User::withTrashed()->find($userId);
$households = $user->households; // Returns children
```

Display in UI:

```php
// Show "Deleted User" for soft-deleted parents
$households = Household::with(['user' => fn($q) => $q->withTrashed()])->get();

foreach ($households as $household) {
    $owner = $household->user?->trashed()
        ? 'Deleted User'
        : $household->user->name;
}
```

## Orchestrated Deletion Processes

Deletion is never instant - it's orchestrated through scheduled jobs with grace periods.

### User Account Deletion

**Process:**
1. User requests account deletion
2. Anonymize personal data immediately (PII compliance)
3. Soft delete user account
4. Wait for compliance grace period (30 days minimum)
5. Hard delete only if required by law

```php
// Step 1 & 2: Anonymize + Soft Delete (immediate)
class DeleteUserAccountAction
{
    public function execute(User $user): void
    {
        DB::transaction(function () use ($user) {
            // Anonymize PII first
            $user->update([
                'name' => 'Deleted User',
                'email' => "deleted_{$user->id}@anonymized.local",
                'password' => Hash::make(Str::random(64)),
                'phone' => null,
                'address' => null,
            ]);

            // Soft delete
            $user->delete();

            // Audit log (see DATA-001-compliance-and-logging)
            AuditLog::create([
                'action' => 'user.account.deleted',
                'actor_id' => $user->id,
                'actor_type' => User::class,
                'subject_id' => $user->id,
                'subject_type' => User::class,
                'metadata' => [
                    'reason' => 'user_requested',
                    'anonymized' => true,
                ],
                'performed_at' => now(),
            ]);
        });
    }
}
```

```php
// Step 3: Hard Delete After Grace Period (scheduled)
// app/Console/Commands/PurgeDeletedUsers.php
class PurgeDeletedUsers extends Command
{
    protected $signature = 'users:purge';

    public function handle(): void
    {
        // Only purge users deleted 30+ days ago
        $users = User::onlyTrashed()
            ->where('deleted_at', '<', now()->subDays(30))
            ->get();

        foreach ($users as $user) {
            // Final audit log before permanent deletion
            AuditLog::create([
                'action' => 'user.account.purged',
                'actor_type' => 'System',
                'subject_id' => $user->id,
                'subject_type' => User::class,
                'metadata' => [
                    'deleted_at' => $user->deleted_at,
                    'purged_at' => now(),
                ],
                'performed_at' => now(),
            ]);

            // Permanent deletion
            $user->forceDelete();
        }

        $this->info("Purged {$users->count()} users");
    }
}
```

Schedule in `routes/console.php` or `bootstrap/app.php`:

```php
Schedule::command('users:purge')->daily();
```

## Business Entity Deletion

**Business entities (Households, Budgets, Transactions, etc.) are NEVER hard deleted:**

```php
// Soft delete only
$household->delete();

// Keep indefinitely for:
// - Analytics and insights
// - Data warehouse operations
// - Audit trails
// - Historical reporting
// - Future ML/AI features
```

### Why Keep Business Data?

- **Analytics:** Understand user behavior patterns, trends, and product usage
- **Data Warehouse:** Power BI, reporting, and business intelligence
- **Audit Compliance:** Complete historical records for financial/legal requirements
- **Recovery:** Restore accidentally deleted data
- **Future Features:** ML models, predictive analytics, recommendations

## When to Force Delete

**Only use `forceDelete()` for:**

1. **User accounts** - After compliance grace period (30+ days)
2. **Test cleanup** - `tearDown()` methods in tests
3. **Data corrections** - Explicit administrative action with approval
4. **Legal requirement** - Court order or regulatory mandate

```php
// Example: Test cleanup only
protected function tearDown(): void
{
    User::withTrashed()->forceDelete();
    parent::tearDown();
}
```

**Never force delete:**
- Business entities (households, budgets, transactions)
- Audit logs
- Financial records
- Historical data

## Data Retention Policy

| Entity Type | Soft Delete | Hard Delete | Retention Reason |
|-------------|-------------|-------------|------------------|
| **Users** | ✅ Immediate (anonymized) | After 30 days | GDPR compliance |
| **Households** | ✅ On user request | ❌ Never | Analytics, audit, warehouse |
| **Budgets** | ✅ On user request | ❌ Never | Analytics, audit, warehouse |
| **Transactions** | ✅ On user request | ❌ Never | Financial records, tax, audit |
| **Payments** | ✅ On user request | ❌ Never | Financial records, compliance |
| **Audit Logs** | ❌ Never | ❌ Never | Legal requirement (7+ years) |

## Compliance Grace Periods

Different regulations have different requirements:

- **GDPR (EU):** 30 days to delete personal data
- **CCPA (California):** 45 days to respond, reasonable time to delete
- **HIPAA (Healthcare):** 6 years minimum retention
- **SOX (Financial):** 7 years minimum retention

**Our Approach:**
- Anonymize PII immediately (satisfies GDPR "erasure")
- Soft delete with 30-day grace period before hard delete
- Business data retained indefinitely for analytics (non-PII)

## Unique Constraints with Soft Deletes

Soft-deleted records should be ignored in unique constraints:

```php
// In FormRequest validation
Rule::unique('households', 'name')
    ->where('user_id', $userId)
    ->whereNull('deleted_at')  // Ignore soft-deleted
```

Or use a unique index in migration that includes `deleted_at`:

```php
$table->unique(['user_id', 'name', 'deleted_at']);
// Allows same name if previous record is soft-deleted
```

## Restoration

Soft-deleted records can be restored:

```php
// Restore soft-deleted record
$household = Household::withTrashed()->find($id);
$household->restore();

// Restore with relationships
$user = User::withTrashed()->find($id);
$user->restore();
$user->households()->restore(); // Restore children too
```

## Archival for Data Warehouse

Soft-deleted records feed into data warehouse:

```php
// Extract soft-deleted records for warehouse
$archivedTransactions = Transaction::onlyTrashed()
    ->where('deleted_at', '>=', now()->subDays(7))
    ->get();

// Send to data warehouse (Snowflake, BigQuery, etc.)
DataWarehouse::sync('transactions_archive', $archivedTransactions);
```

## Key Points

- ✅ Soft delete is the default for ALL entities
- ✅ Use `SoftDeletes` trait on all models
- ✅ Anonymize user PII before soft delete
- ✅ Orchestrate deletion through scheduled jobs with grace periods
- ✅ Keep business data indefinitely for analytics and warehouse
- ✅ Hard delete users only after compliance grace period (30+ days)
- ❌ Never use `cascadeOnDelete()` or `nullOnDelete()`
- ❌ Never force delete business entities
- ❌ Never instant deletion - always orchestrated with grace period

## Related

- `DATA-001-compliance-and-logging` - How to log deletion events without PII
- `AUDIT-*` - Audit logging patterns for compliance
- `MODEL-001-structure` - Model configuration with SoftDeletes
