---
overrides: base/http/resources/RESOURCE-001-api-resources.md
target: laravel-12
reason: Laravel 12 lacks JsonApiResource — only the standard JsonResource is available.
base-hash: 4313cb
---

> ⚠️ **Laravel 12 — only JsonResource available.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# RESOURCE-001-api-resources

## Pattern

Transform Eloquent models for API responses. Never expose raw models.

Laravel 12 offers a single base class:
- **`JsonResource`** — flat, ad-hoc shape you define in `toArray()`. The default for most internal APIs.

The JSON:API-compliant `JsonApiResource` is not available on Laravel 12; if you need JSON:API conventions, build the envelope by hand in `toArray()` or upgrade.

## JsonResource (default)

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'reference' => $this->reference,
            'status' => $this->status->value,
            'total_cents' => $this->total_cents,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
        ];
    }
}
```

Explicit field mapping is a whitelist — only what you list is exposed. Generate with
`php artisan make:resource OrderResource`.

## Conditional Relationships

Only include relationships when they're loaded (prevents N+1):

```php
public function toArray(Request $request): array
{
    return [
        'id' => $this->id,
        'reference' => $this->reference,

        // Load related resource only when the relationship is loaded
        'user' => new UserResource($this->whenLoaded('user')),

        // With a callback for more control
        'owner' => $this->whenLoaded('owner', fn () => [
            'id' => $this->owner->id,
            'name' => $this->owner->name,
        ]),

        // Conditional counts
        'items_count' => $this->whenCounted('items'),

        'created_at' => $this->created_at->toISOString(),
    ];
}
```

## Returning resources

```php
return new OrderResource($order);              // single
return OrderResource::collection($orders);     // collection
```

## Key Points

- Use `JsonResource` for all APIs — explicit field mapping (whitelist, not blacklist)
- **L12: `JsonApiResource` is not available** — hand-build the JSON:API envelope in `toArray()` if you need it
- Use `toISOString()` for dates
- `$this->whenLoaded()` to conditionally include relationships; `$this->whenCounted()` for counts
- Never expose sensitive fields (passwords, tokens, etc.)
- Cast enum-backed fields with `->value`
