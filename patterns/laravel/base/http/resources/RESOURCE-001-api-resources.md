# RESOURCE-001-api-resources

## Pattern

Transform Eloquent models for API responses. Never expose raw models.

Laravel 13 offers two base classes:
- **`JsonResource`** — flat, ad-hoc shape you define in `toArray()`. The default for most internal APIs.
- **`JsonApiResource`** — JSON:API spec-compliant (`type` / `id` / `attributes` / `relationships` / `links`). Use when consumers expect JSON:API conventions or you want sparse fieldsets and standardized relationship envelopes.

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

## JsonApiResource (Laravel 13)

When the API follows the JSON:API spec, extend `JsonApiResource`. It's first-party in Laravel
13 and **extends `JsonResource`** — but instead of hand-building the envelope in `toArray()`,
you declare `$attributes` and `$relationships`. The framework produces the
`type`/`id`/`attributes`/`relationships`/`links` structure, handles sparse fieldsets
(`?fields[orders]=reference,status`), include parsing (`?include=user,items`), and sets the
`application/vnd.api+json` content type.

Generate with `php artisan make:resource OrderResource --json-api`:

```php
<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Resources\JsonApi\JsonApiResource;

class OrderResource extends JsonApiResource
{
    /** The resource's attributes. */
    public $attributes = [
        'reference',
        'status',
        'total_cents',
        'created_at',
    ];

    /** The resource's relationships. */
    public $relationships = [
        'user' => UserResource::class,
        'items' => OrderItemResource::class,
    ];
}
```

For relationships that need conditional logic or closures, override `toRelationships()` instead
of the property:

```php
use Illuminate\Http\Request;

public function toRelationships(Request $request): array
{
    return [
        'user' => UserResource::class,
        'items' => fn () => OrderItemResource::collection($this->items),
    ];
}
```

### When to use JsonApiResource

- Public APIs where consumers expect JSON:API conventions
- Need sparse fieldsets (`?fields[type]=...`) without custom logic
- Need standardized relationship envelopes for nested includes
- Cross-team / cross-org integrations that benefit from a known spec

For internal-only or simple APIs, stick with `JsonResource` — JSON:API adds verbosity that's
only worth it when consumers benefit.

## Returning resources

```php
return new OrderResource($order);              // single
return OrderResource::collection($orders);     // collection
return $order->toResource(OrderResource::class);          // convenience
return $orders->toResourceCollection(OrderResource::class);
```

## Key Points

- Default to `JsonResource` for most APIs — explicit field mapping (whitelist, not blacklist)
- **L13: use `JsonApiResource` (`Illuminate\Http\Resources\JsonApi\JsonApiResource`) when following the JSON:API spec** — declare `$attributes` + `$relationships`, don't hand-build the envelope
- Use `toISOString()` for dates
- `$this->whenLoaded()` to conditionally include relationships; `$this->whenCounted()` for counts
- Never expose sensitive fields (passwords, tokens, etc.)
- Cast enum-backed fields with `->value`
