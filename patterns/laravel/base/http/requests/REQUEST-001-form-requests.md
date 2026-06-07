# REQUEST-001-form-requests

## Pattern

FormRequest classes for validation of HTTP requests.

## Why

- Separates validation logic from controllers
- Type-safe validation rules
- Can be reused across multiple controller methods
- Hands validated input to Actions as a typed object

## DTO vs Data Object (the two handoff methods)

A FormRequest converts validated input into a typed object for the Action. There are two kinds,
distinguished by **mutability** — the method name tells the caller which they get:

| Method | Returns | Mutability | Use for |
|--------|---------|------------|---------|
| `toDto()` | a DTO | **immutable** (`readonly`) | the common case — create/update input, commands, anything passed between layers and then discarded |
| `toData()` | a Data Object | **mutable** | persisted JSON-column state (settings, preferences, config) that gets replaced wholesale |

Both live in `app/Data/`. Most FormRequests use `toDto()`. Reach for `toData()` only when the
request is editing a mutable, persisted Data Object.

## When to Use a Typed Object at All

**Emit a DTO/Data Object when:**
- The data is reused in jobs, commands, or other contexts
- You have 4+ parameters
- You want a type-safe, portable object

**Skip it (use `$request->validated()` directly) when:**
- Very niche request (1–3 params)
- Never reused anywhere else
- Simple one-off operations (e.g., toggle a flag, update a single field)

## Example: With a DTO (immutable — the common case)

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use App\Data\CreateOrderData;
use Illuminate\Foundation\Http\FormRequest;

class CreateOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'product_id' => ['required', 'integer', 'exists:products,id'],
            'quantity' => ['required', 'integer', 'min:1'],
        ];
    }

    public function toDto(): CreateOrderData
    {
        $validated = $this->validated();

        return new CreateOrderData(
            productId: $validated['product_id'],
            quantity: $validated['quantity'],
        );
    }
}
```

Controller usage:
```php
public function store(CreateOrderRequest $request, CreateOrderAction $action): OrderResource
{
    $order = $action->execute($request->toDto());

    return new OrderResource($order);
}
```

## Example: Without a Typed Object (simple one-off)

```php
<?php

declare(strict_types=1);

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ArchiveOrderRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'reason' => ['nullable', 'string', 'max:500'],
        ];
    }
}
```

Controller usage:
```php
public function archive(ArchiveOrderRequest $request, Order $order)
{
    // Simple - no DTO needed for one optional param
    $order->archive($request->validated('reason'));

    return response()->json(['message' => 'Order archived']);
}
```

## authorize()

Return `true`. Authorization lives on the controller via `#[Authorize]`, not in the FormRequest.

```php
public function authorize(): bool
{
    return true;
}
```

## Conditional Validation

```php
public function rules(): array
{
    $rules = [
        'name' => ['required', 'string', 'max:100'],
    ];

    // Only validate tier-specific fields for pro users
    if ($this->user()->isPro()) {
        $rules['max_seats'] = ['required', 'integer', 'min:1', 'max:20'];
    } else {
        $rules['max_seats'] = ['required', 'integer', 'min:1', 'max:5'];
    }

    return $rules;
}
```

## Key Points

- Lives in `app/Http/Requests/`
- Name pattern: descriptive of the action (`CreateOrderRequest`, `SendNotificationRequest`, `ProcessPaymentRequest`)
- Define validation rules inline; use custom Rule objects for reusable field-specific rules
- `toDto()` for an **immutable** DTO (the common case); `toData()` for a **mutable** Data Object
- `authorize()` returns `true` — authorization is on the controller (`#[Authorize]`), not here
- Laravel's default error messages are usually sufficient; add `messages()` only for non-obvious rules
