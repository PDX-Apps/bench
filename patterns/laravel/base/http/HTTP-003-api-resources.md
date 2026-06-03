# HTTP-003-api-resources

## Pattern

Transform Eloquent models for API responses. Never expose raw models.

Laravel 13 offers two base classes:
- **`JsonResource`** — flat, ad-hoc shape. The default for most internal APIs.
- **`JsonApiResource`** — JSON:API spec-compliant (`type` / `id` / `attributes` / `relationships` / `links`). Use when consumers expect JSON:API conventions or you want sparse fieldsets and standardized relationship envelopes.

## JsonResource (default — same as L12)

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

## JsonApiResource (Laravel 13)

When the API needs to follow the JSON:API spec — typed resource envelopes, relationship objects, sparse fieldsets, includes — extend `JsonApiResource` instead:

```php
<?php

declare(strict_types=1);

namespace Modules\Bill\Http\Resources;

use Illuminate\Http\Resources\Json\JsonApiResource;

class BillJsonApiResource extends JsonApiResource
{
    public function toArray($request): array
    {
        return [
            'type' => 'bills',
            'id' => (string) $this->public_id,
            'attributes' => [
                'name' => $this->name,
                'amount' => $this->amount,
                'currency' => $this->currency,
                'status' => $this->status->value,
                'created_at' => $this->created_at->toISOString(),
            ],
            'relationships' => [
                'household' => [
                    'data' => $this->whenLoaded('household', fn () => [
                        'type' => 'households',
                        'id' => (string) $this->household->public_id,
                    ]),
                ],
                'members' => [
                    'data' => $this->whenLoaded('members', fn () => $this->members->map(
                        fn ($m) => ['type' => 'bill-members', 'id' => (string) $m->public_id]
                    )),
                ],
            ],
            'links' => [
                'self' => route('api.bills.show', $this->public_id),
            ],
        ];
    }
}
```

The framework handles top-level wrappers (`data`, `included`, `links`, `meta`), sparse fieldset filtering (`?fields[bills]=name,amount`), and include parsing (`?include=household,members`).

### When to use JsonApiResource

- Public APIs where consumers expect JSON:API conventions
- Need sparse fieldsets (`?fields[type]=...`) without custom logic
- Need standardized relationship envelopes for nested includes
- Cross-team / cross-org integrations that benefit from a known spec

For internal-only or simple APIs, stick with `JsonResource` — JSON:API adds verbosity that's only worth it when consumers benefit.

## Conditional Relationships (both classes)

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
        'owner' => $this->whenLoaded('owner', fn () => [
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

- Default to `JsonResource` for most APIs — explicit field mapping (whitelist, not blacklist)
- **L13: use `JsonApiResource` when the API follows the JSON:API spec** (typed envelopes, relationship objects, sparse fieldsets)
- Use `toISOString()` for dates
- Use `$this->whenLoaded()` to conditionally include relationships
- Use `$this->whenCounted()` for counts
- Never expose sensitive fields (passwords, tokens, etc.)
- For entities that have a `public_id`, use `public_id` as `id` instead, and omit `public_id` from the response
- `JsonApiResource` ID values must be strings per spec — cast with `(string)` if your column is a ULID/UUID/integer
