# CAST-002-enums

## Pattern

Casting an enum-typed column on an Eloquent model. Laravel casts backed enums natively — no custom `CastsAttributes` class needed; just register the enum in the model's `casts()` method and the attribute reads/writes as an enum instance.

## Registering on a model

```php
use App\Enums\OrderStatus;

class Order extends Model
{
    protected function casts(): array
    {
        return [
            'status' => OrderStatus::class,
        ];
    }
}
```

## Usage through the model

```php
// Assignment — assign the enum case, not its string value
$order->status = OrderStatus::Placed;
$order->save();

// Reading — the attribute is an enum instance
$order->status;          // OrderStatus::Placed
$order->status->value;   // 'placed' (raw DB value, e.g. for an API response)

// Querying — pass the case; Laravel binds its value
Order::where('status', OrderStatus::Placed)->get();
```

The column should be a `string` (or `integer` for int-backed enums) in the migration — match the enum's backing type.

## Anti-Patterns

- ❌ `protected $casts = [...]` array property — the `casts()` method is the current form; the array property is the older style
- ❌ Storing/reading the raw string and converting by hand — register the cast and let Eloquent hydrate the enum
