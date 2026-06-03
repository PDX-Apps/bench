# Standard Responses

Laravel provides automatic HTTP error responses for common scenarios. Controllers using route model binding, policy middleware, and form requests do NOT need to manually return these responses.

## Automatic Responses

### 404 Not Found

**Source:** Route model binding (`Route::resource` or `{model}` parameter)

When model not found or soft-deleted, Laravel automatically returns:
```json
{
  "message": "Not Found"
}
```

**When it triggers:**
- Resource doesn't exist in database
- Soft-deleted resource accessed without `withTrashed()`
- ID doesn't match user's ownership (if scoped query used)

**Implementation:**
```php
// ✅ Laravel handles this automatically
Route::apiResource('households', HouseholdController::class);

public function show(Household $household)
{
    // 404 returned automatically if not found
    return new HouseholdResource($household);
}
```

### 403 Forbidden

**Source:** Policy authorization (via `->can()` on routes or `authorizeResource()`)

When user lacks permission, Laravel automatically returns:
```json
{
  "message": "This action is unauthorized."
}
```

**When it triggers:**
- Policy method returns `false`
- User doesn't own the resource
- User lacks required role/permission

**Implementation:**
```php
// Resource controllers: authorizeResource() in constructor
Route::apiResource('households', HouseholdController::class);

// Action routes: ->can() on route definition (see HTTP-004-routes)
Route::post('invitations/{invitation}/accept', [InvitationResponseController::class, 'accept'])
    ->can('accept', 'invitation');
```

### 401 Unauthorized

**Source:** Auth middleware (`auth:sanctum`)

When not authenticated, Laravel automatically returns:
```json
{
  "message": "Unauthenticated."
}
```

**When it triggers:**
- No auth token provided
- Invalid/expired token
- User not found

**Implementation:**
```php
// ✅ Auth checked automatically via middleware
Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('households', HouseholdController::class);
});
```

### 422 Unprocessable Entity

**Source:** Form Request validation

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

**When it triggers:**
- Form Request validation rules fail
- Manual validation in controller fails

**Implementation:**
```php
// ✅ Validation runs automatically, 422 returned on failure
public function store(CreateHouseholdRequest $request)
{
    // Request only reaches here if validation passed
    $household = Household::create($request->validated());
    return new HouseholdResource($household);
}
```

## When to Document Custom Responses

Only document non-standard responses in SPEC files:
- ❌ Don't document 404/403/401/422 (standard Laravel behavior)
- ✅ Do document 409 Conflict (custom business logic)
- ✅ Do document 429 Too Many Requests (rate limiting)
- ✅ Do document custom error structures

## Anti-Pattern: Manual Response Handling

**❌ DON'T DO THIS:**
```php
public function show($id)
{
    $household = Household::find($id);

    if (!$household) {
        return response()->json(['message' => 'Not Found'], 404);
    }

    if ($household->user_id !== auth()->id()) {
        return response()->json(['message' => 'Forbidden'], 403);
    }

    return new HouseholdResource($household);
}
```

**✅ DO THIS:**
```php
public function show(Household $household)
{
    // Route model binding handles 404
    // Policy middleware handles 403
    return new HouseholdResource($household);
}
```

## Related

- `HTTP-001-resource-controllers` - Controller patterns
- `POLICY-001-resource-policies` - Authorization
- `HTTP-002-form-requests` - Validation
