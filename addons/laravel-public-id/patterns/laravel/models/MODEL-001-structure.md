---
mode: append
---

## Public IDs (this project uses bench-laravel-public-id)

Expose a **ULID `public_id`** in the API; keep the integer `id` as the internal primary key (fast joins/indexes). Resolve route-model binding on `public_id`.

```php
use Illuminate\Support\Str;

class Order extends Model
{
    // never expose or mass-assign the public id
    protected $guarded = ['id', 'public_id'];

    protected static function booted(): void
    {
        static::creating(function (self $order): void {
            $order->public_id ??= (string) Str::ulid();
        });
    }

    public function getRouteKeyName(): string
    {
        return 'public_id';
    }
}
```

- Generate `public_id` in a `creating` hook inside **`booted()`** (not the legacy `boot()`), or a dedicated observer.
- Keep the integer `id` for relationships/joins; never expose it.
- Route-model binding resolves on `public_id` via `getRouteKeyName()`.
- Simpler all-ULID alternative: make the ULID the primary key with Laravel's `HasUlids` trait (drops the int `id`) — use only if you don't need int-join performance.
