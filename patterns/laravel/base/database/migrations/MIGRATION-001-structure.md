# MIGRATION-001-structure

## Pattern

Database migrations for creating and modifying tables.

## Structure

```php
<?php

declare(strict_types=1);

use App\Models\Order;
use App\Models\User;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->foreignIdFor(User::class)->constrained();
            $table->string('reference')->unique();
            $table->string('status', 20)->index();
            $table->unsignedBigInteger('total_cents');
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('orders');
    }
};
```

## Foreign Keys

Use `foreignIdFor()` with a model class reference and `->constrained()` for automatic
constraint naming:

```php
$table->foreignIdFor(User::class)->constrained();

// Custom column name + table
$table->foreignIdFor(User::class, 'created_by')->constrained('users');
```

Default to plain `->constrained()` (RESTRICT) — do **not** add `cascadeOnDelete()` or
`nullOnDelete()`. The deletion strategy (soft deletes, application-controlled cascades) is a
schema-wide convention covered in the soft-deletes pattern.

## Enum vs String Columns

When a column holds a fixed set of values backed by an enum, choose the column type by table
size and how often the value set changes:

```php
use App\Enums\OrderStatus;

// Use $table->enum() when values are stable and the table is small/medium:
$table->enum('status', array_column(OrderStatus::cases(), 'value'));

// Use $table->string()->index() when values change often or the table is large
// (altering an enum column can lock big tables for a long time):
$table->string('status', 20)->index();
```

**When in doubt, use `string` with an index** — it avoids the migration risk of altering an
enum column on a large table.

## Modifying Tables

```php
public function up(): void
{
    Schema::table('orders', function (Blueprint $table) {
        $table->string('channel', 30)->nullable()->after('status');
    });
}

public function down(): void
{
    Schema::table('orders', function (Blueprint $table) {
        $table->dropColumn('channel');
    });
}
```

`change()` drops any attribute not re-specified — re-declare the full column definition
(type, length, nullable, default) plus your change, not just the delta.

## Key Points

- `declare(strict_types=1)` at the top; import model and enum classes
- `foreignIdFor({Model}::class)->constrained()` for foreign keys; default RESTRICT (omit cascade/null)
- `$table->enum()` for small tables with stable values; `$table->string()->index()` otherwise
- `$table->timestamps()` and `$table->softDeletes()` on most tables
- Always implement a reversible `down()`
- On `change()`, re-specify every attribute the column should keep
