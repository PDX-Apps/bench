# AUTH-002-api

## Pattern

Token-based authentication using Laravel Sanctum for mobile apps and external API consumers.

## When to Use

Use this authentication method when explicitly building API endpoints for:

- Mobile applications
- Third-party API integrations
- External service consumers
- Different domains

## Middleware

```php
Route::middleware(['auth:sanctum'])->group(function () {
    Route::apiResource('households', HouseholdController::class);
});
```

## Client Authentication

- Bearer token in Authorization header
- `Authorization: Bearer {token}`

## Specification Format

When documenting API-only endpoints, specify explicitly:

```markdown
## Endpoint

\```
POST /api/households
Content-Type: application/json
Authorization: Bearer {token}
\```

**Authentication:** API token (see AUTH-002-api)
```

## Related

- **AUTH-001-web** - Session-based authentication (default)
- **POLICY-001** - Authorization handled via policies
