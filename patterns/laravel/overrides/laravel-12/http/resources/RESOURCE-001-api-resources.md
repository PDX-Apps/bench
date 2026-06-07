---
overrides: base/http/resources/RESOURCE-001-api-resources.md
target: laravel-12
reason: Laravel 12 lacks JsonApiResource — only the standard JsonResource is available.
base-hash: fad1b3
---

> ⚠️ **Laravel 12 — only JsonResource available.** This override exists for projects still on this older version. New projects should use the base (latest version) patterns.

# RESOURCE-001-api-resources

## Pattern

Transform Eloquent models for API responses. Never expose raw models.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Resources;

use Illuminate\Http\Resources\Json\JsonResource;

class {Model}Resource extends JsonResource
{
    public function toArray($request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'created_at' => $this->created_at->toISOString(),
            'updated_at' => $this->updated_at->toISOString(),
        ];
    }
}
```

## Conditional Relationships

Only include relationships when they're loaded (prevents N+1):

```php
public function toArray($request): array
{
    return [
        'id' => $this->id,
        'name' => $this->name,

        // Load related resource only when the relationship is loaded
        'user' => new UserResource($this->whenLoaded('user')),

        // With callback for more control
        'owner' => $this->whenLoaded('owner', fn() => [
            'id' => $this->owner->id,
            'name' => $this->owner->name,
        ]),

        // Conditional counts
        'members_count' => $this->whenCounted('members'),

        'created_at' => $this->created_at->toISOString(),
        'updated_at' => $this->updated_at->toISOString(),
    ];
}
```

## Key Points

- Explicit field mapping (whitelist, not blacklist)
- Use `toISOString()` for dates
- Use `$this->whenLoaded()` to conditionally include relationships
- Use `$this->whenCounted()` for counts
- Never expose sensitive fields (passwords, tokens, etc.)
- For entities that have a `public_id`, use `public_id` as `id` instead, and omit `public_id` from the response
