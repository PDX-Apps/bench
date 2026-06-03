# DB-001-migrations

## Pattern

Database migrations for creating and modifying tables.

## Structure

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use App\Models\User;
use Modules\Household\Models\Household;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('households', static function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->foreignIdFor(User::class)->nullable()->constrained()->nullOnDelete();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('households');
    }
};
```

## Enum vs String Columns

When using enums (see CODE-003-enums), choose column type carefully:

```php
use Modules\Household\Enums\InvitationType;

// ✅ Use $table->enum() when:
// - Values rarely/never change
// - Table size < millions of rows
// - Enum changes would complete in reasonable time
$types = array_map(fn($case) => $case->value, InvitationType::cases());
$table->enum('type', $types);

// ✅ Use $table->string() + index when:
// - Values change frequently
// - Table is huge (enum changes could take hours/days)
// - Need flexibility for future values
$table->string('status', 20)->index();
```

**Migration risk:** Changing enum values on large tables can lock the table for extended periods. When in doubt, use `string` with an index.

## Foreign Keys

Use `foreignIdFor()` with model class reference. Choose delete behavior based on relationship type:

```php
// Parent-child ownership: cascade delete
// (Child is meaningless without parent)
$table->foreignIdFor(Household::class)
    ->constrained()
    ->cascadeOnDelete();

// Optional reference: null on delete
// (Entity can exist without referenced record)
$table->foreignIdFor(User::class)
    ->nullable()
    ->constrained()
    ->nullOnDelete();

// Required reference with preservation: restrict delete
// (Prevent deletion if referenced, or handle in application)
$table->foreignIdFor(User::class, 'created_by')
    ->constrained('users')
    ->restrictOnDelete();
```

**Default Pattern:**
- Use `->restrictOnDelete()` or omit (defaults to RESTRICT)
- Rely on soft deletes for data retention and relationship integrity
- Never use `cascadeOnDelete()` or `nullOnDelete()` - see DATA-002-deletion-and-retention

**Rationale:**
- Soft deletes preserve all data for analytics and audit trails
- Parent-child relationships maintained through soft delete timestamps
- Data warehouse benefits from complete historical records
- Orchestrated deletion processes handle compliance requirements

## Key Points

- Use `foreignIdFor({Model}::class)` for foreign keys
- Always add `->constrained()` for automatic constraint naming
- Use `->restrictOnDelete()` or omit for default RESTRICT behavior
- Never use `cascadeOnDelete()` or `nullOnDelete()` - rely on soft deletes instead
- See DATA-002-deletion-and-retention for data retention patterns
- Use `$table->enum()` for small tables with stable values
- Use `$table->string()->index()` for large tables or frequently changing values
- Import model classes and enums at the top
- Timestamps with `$table->timestamps()`
- For public-facing entities, consider adding Public IDs (see DB-004-public-ids)
