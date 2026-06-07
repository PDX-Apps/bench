---
mode: append
---

## Exposing the public ID (this project uses bench-laravel-public-id)

Surface `public_id` as the resource's `id`; never expose the internal integer `id`:

```php
public function toArray(Request $request): array
{
    return [
        'id' => $this->public_id,   // ULID, not the internal auto-increment
        // ... other fields
    ];
}
```

- The API's `id` is always the `public_id`. Internal `id` stays out of every resource.
- Related-resource links use the parent/child `public_id` too.
