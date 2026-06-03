# HTTP-002-form-requests

## Pattern

FormRequest classes for validation of HTTP requests.

## Why

- Separates validation logic from controllers
- Type-safe validation rules
- Can be reused across multiple controller methods
- Integrates with DTOs for clean data transfer
- For self-validating DTOs with rules, see DTO-002-self-validating

## When to Use DTOs

**Use DTOs when:**
- Data will be reused in jobs, commands, or other contexts
- You have 4+ parameters
- Validation logic should be portable
- You want type-safe data objects

**Skip DTOs when:**
- Very niche request (1-3 params)
- Never reused anywhere else
- Simple one-off operations (e.g., toggle a flag, update a single field)

## toDto() vs toData()

| Method | Returns | Use Case |
|--------|---------|----------|
| `toDto()` | `readonly` DTO | Immutable request data, commands |
| `toData()` | Mutable Data Object | Settings, preferences (see `DATA-007`) |

## Example: With DTO (Reusable Data)

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Requests;

use App\Http\Requests\FormRequest;
use Modules\{Module}\Data\CreateOrderData;

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
public function store(CreateOrderRequest $request)
{
    $dto = $request->toDto();
    $order = $this->action->execute($dto);

    return response()->json(['data' => new OrderResource($order)], 201);
}
```

## Example: Without DTO (Simple One-Off)

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Http\Requests;

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
    // Simple - no DTO needed for 1 optional param
    $order->archive($request->validated('reason'));

    return response()->json(['message' => 'Order archived']);
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
        $rules['max_members'] = ['required', 'integer', 'min:1', 'max:20'];
    } else {
        $rules['max_members'] = ['required', 'integer', 'min:1', 'max:5'];
    }

    return $rules;
}
```

## Key Points

- Lives in `Modules/{Module}/Http/Requests/`
- Name pattern: Descriptive of the action (CreateOrderRequest, SendNotificationRequest, ProcessPaymentRequest)
- Define validation rules inline - reference domain VAL-* files for field-specific rules
- For self-validating DTOs, see DTO-002-self-validating pattern
- Use `toDto()` for immutable DTOs, `toData()` for mutable Data Objects
- Laravel's default error messages are usually sufficient
