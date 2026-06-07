# MIGRATION-002-soft-deletes

## Pattern

Soft deletes and foreign-key delete behavior. Default to soft deletes so records can be recovered, queried for analytics, and excluded from normal reads automatically.

## Default: Soft Delete

### Migration

```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();
    // ... other columns
    $table->softDeletes();
});
```

### Model

```php
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use SoftDeletes;
    // Queries automatically exclude soft-deleted records
}
```

### Deleting and querying

```php
$order->delete();              // soft delete — sets deleted_at

Order::where('user_id', $id)->get();   // excludes soft-deleted
Order::withTrashed()->find($id);       // include soft-deleted
Order::onlyTrashed()->get();           // only soft-deleted
```

## Foreign keys: avoid cascade / set null

Default to `constrained()` for referential integrity **without** cascading deletes:

```php
Schema::create('order_items', function (Blueprint $table) {
    $table->id();
    $table->foreignId('order_id')->constrained();  // integrity only
    $table->softDeletes();
});
```

`cascadeOnDelete()` and `nullOnDelete()` push deletion into the database, which loses records you may want to recover or analyze and removes control over the deletion process. Prefer soft-deleting the parent and handling children in application code.

### Soft-deleted parents

When a parent is soft-deleted, children remain. Reach the parent through `withTrashed()`:

```php
$order = Order::withTrashed()->find($id);
$items = $order->items;

// In UI, account for trashed parents
$items = OrderItem::with(['order' => fn ($q) => $q->withTrashed()])->get();
$label = $item->order?->trashed() ? 'Deleted order' : $item->order->reference;
```

## Unique constraints

Ignore soft-deleted rows so a value can be reused after its record is trashed:

```php
// FormRequest validation
Rule::unique('subscriptions', 'name')
    ->where('user_id', $userId)
    ->whereNull('deleted_at');
```

```php
// Or include deleted_at in a unique index
$table->unique(['user_id', 'name', 'deleted_at']);
```

## Restoring

```php
$order = Order::withTrashed()->find($id);
$order->restore();
```

## Force delete

`forceDelete()` removes the row permanently. Reserve it for cases where keeping the record has no value — e.g. test teardown:

```php
protected function tearDown(): void
{
    Order::withTrashed()->forceDelete();
    parent::tearDown();
}
```

## Key Points

- Default to `SoftDeletes` so deletes are recoverable and excluded from reads automatically
- Use `constrained()` for FK integrity; avoid `cascadeOnDelete()` / `nullOnDelete()` so the app controls deletion
- Soft-deleted parents keep their children — reach them via `withTrashed()`
- Add `deleted_at` to unique constraints so values can be reused after a soft delete
- `forceDelete()` only when the record genuinely has no further value
