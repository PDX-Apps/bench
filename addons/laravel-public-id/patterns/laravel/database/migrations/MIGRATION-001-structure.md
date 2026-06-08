---
mode: append
---

## Public ID column (this project uses laravel-public-id)

Add a unique `public_id` (ULID) alongside the integer primary key:

```php
Schema::create('orders', function (Blueprint $table) {
    $table->id();                      // internal primary key (never exposed)
    $table->ulid('public_id')->unique(); // public-facing identifier
    // ... other columns
    $table->timestamps();
});
```

- `id()` stays the primary key for fast joins; `public_id` is indexed (`unique()`) for lookups.
- Use `$table->ulid('public_id')` (or `uuid()` if the project standardizes on UUIDs).
