# RESPONSE-001-standard

Laravel provides automatic HTTP error responses for common scenarios. Controllers using route
model binding, the `#[Authorize]` attribute, and form requests do NOT need to manually return
these responses.

## Automatic Responses

### 404 Not Found

**Source:** Route model binding (`Route::apiResource` / `Route::resource` or a `{model}` parameter)

When the model isn't found (or is soft-deleted), Laravel automatically returns:
```json
{
  "message": "Not Found"
}
```

```php
// ✅ Laravel handles this automatically
Route::apiResource('orders', OrderController::class);

public function show(Order $order)
{
    // 404 returned automatically if not found
    return new OrderResource($order);
}
```

### 403 Forbidden

**Source:** Policy authorization via the `#[Authorize]` attribute on the controller method.

When the policy denies the action, Laravel automatically returns:
```json
{
  "message": "This action is unauthorized."
}
```

```php
use Illuminate\Routing\Attributes\Controllers\Authorize;

#[Authorize('update', 'order')]
public function update(UpdateOrderRequest $request, Order $order) { /* ... */ }
```

(Authorization lives on the controller, not the route — see the controller and routing patterns.)

### 401 Unauthorized

**Source:** Auth middleware (`auth:sanctum`)

When unauthenticated, Laravel automatically returns:
```json
{
  "message": "Unauthenticated."
}
```

```php
// ✅ Auth checked automatically via middleware
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('orders', OrderController::class);
});
```

### 422 Unprocessable Entity

**Source:** FormRequest validation

When validation fails, Laravel automatically returns:
```json
{
  "message": "The name field is required. (and 1 more error)",
  "errors": {
    "name": ["The name field is required."],
    "email": ["The email field must be a valid email address."]
  }
}
```

```php
// ✅ Validation runs automatically, 422 returned on failure
public function store(CreateOrderRequest $request, CreateOrderAction $action): OrderResource
{
    // Reached only if validation passed
    return new OrderResource($action->execute($request->user(), $request->toDto()));
}
```

## When to Document Custom Responses

Only document non-standard responses:
- ❌ Don't document 404/403/401/422 (standard Laravel behavior)
- ✅ Do document 409 Conflict (custom business logic)
- ✅ Do document 429 Too Many Requests (rate limiting)
- ✅ Do document custom error structures

## Anti-Pattern: Manual Response Handling

**❌ DON'T:**
```php
public function show($id)
{
    $order = Order::find($id);

    if (! $order) {
        return response()->json(['message' => 'Not Found'], 404);
    }

    if ($order->user_id !== $request->user()->id) {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    return new OrderResource($order);
}
```

**✅ DO:**
```php
#[Authorize('view', 'order')]
public function show(Order $order)
{
    // Route model binding handles 404; #[Authorize] handles 403
    return new OrderResource($order);
}
```

## Key Points

- Let Laravel return 404 (route model binding), 403 (`#[Authorize]`), 401 (`auth:sanctum`), 422 (FormRequest) automatically
- Don't hand-roll these in controllers
- Only document/handle genuinely custom responses (409, 429, custom error shapes)
