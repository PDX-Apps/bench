# AUTH-003-auth-service

## Pattern

Injectable auth service providing type-safe helpers for accessing authenticated user data in Actions and Services.

## Why

Laravel's `auth()->id()` returns `mixed|null`, requiring repeated validation in every Action to satisfy static analysis tools and ensure type safety. This service centralizes auth access with proper type guarantees.

## Dependencies

- `SERVICE-001-actions` - Used in Action classes

## Structure

```php
<?php

declare(strict_types=1);

namespace App\Services;

use App\Models\User;
use Illuminate\Auth\AuthenticationException;

/**
 * Provides type-safe access to authenticated user data.
 */
class AuthService
{
    /**
     * Get the authenticated user's ID.
     *
     * @throws AuthenticationException If user not authenticated or ID is invalid
     */
    public function userId(): int
    {
        $userId = auth()->id();

        if (!is_int($userId) || $userId < 1) {
            throw new AuthenticationException('User is not authenticated or ID is invalid.');
        }

        return $userId;
    }

    /**
     * Get the authenticated user.
     *
     * @throws AuthenticationException If user not authenticated
     */
    public function user(): User
    {
        $user = auth()->user();

        if (!$user instanceof User) {
            throw new AuthenticationException('User is not authenticated.');
        }

        return $user;
    }

    /**
     * Check if user is authenticated.
     */
    public function check(): bool
    {
        return auth()->check();
    }

    /**
     * Check if user is a guest.
     */
    public function guest(): bool
    {
        return auth()->guest();
    }
}
```

## Usage in Actions

### ❌ Before (Repeated validation)

```php
class CreateHouseholdAction
{
    public function execute(HouseholdData $data): Household
    {
        $userId = auth()->id();

        if (!is_int($userId) || $userId < 1) {
            throw new RuntimeException('User ID is not valid.');
        }

        $household = new Household();
        $household->name = $data->name;
        $household->user_id = $userId;
        $household->save();

        return $household;
    }
}
```

### ✅ After (Clean and type-safe)

```php
class CreateHouseholdAction
{
    public function __construct(
        private readonly AuthService $auth
    ) {}

    public function execute(HouseholdData $data): Household
    {
        $household = new Household();
        $household->name = $data->name;
        $household->user_id = $this->auth->userId(); // Type-safe int
        $household->save();

        return $household;
    }
}
```

## Usage in Controllers

Controllers don't need AuthService - use middleware and typehinted requests:

```php
// ❌ DON'T use AuthService in controllers
class HouseholdController extends Controller
{
    public function __construct(private readonly AuthService $auth) {} // NO

    public function store(CreateHouseholdRequest $request)
    {
        $userId = $this->auth->userId(); // NO
    }
}

// ✅ DO use request helper
class HouseholdController extends Controller
{
    public function store(
        CreateHouseholdRequest $request,
        CreateHouseholdAction $action
    ): JsonResponse {
        // Auth middleware ensures user() is not null
        $household = $action->execute($request->toData());

        return (new HouseholdResource($household))
            ->response()
            ->setStatusCode(201);
    }
}
```

## Testing

Mock AuthService in tests:

```php
use App\Services\AuthService;
use Illuminate\Auth\AuthenticationException;

test('creates household with authenticated user', function () {
    $authService = Mockery::mock(AuthService::class);
    $authService->shouldReceive('userId')->once()->andReturn(1);

    $action = new CreateHouseholdAction($authService);
    $household = $action->execute(new HouseholdData(name: 'Test'));

    expect($household->user_id)->toBe(1);
});

test('throws exception when user not authenticated', function () {
    $authService = Mockery::mock(AuthService::class);
    $authService->shouldReceive('userId')
        ->once()
        ->andThrow(new AuthenticationException());

    $action = new CreateHouseholdAction($authService);
    $action->execute(new HouseholdData(name: 'Test'));
})->throws(AuthenticationException::class);
```

## When to Use

**✅ Use AuthService in:**
- Actions that need user ID or user object
- Domain services that require auth context
- Background jobs that process user-specific data

**❌ Don't use AuthService in:**
- Controllers (use `$request->user()` with middleware)
- Policies (use typehinted `User $user` parameter)
- Request classes (use `$this->user()`)
- Middleware (use `auth()->check()` directly)

## Key Points

- Lives in `app/Services/AuthService.php`
- Returns `int` for userId() (never null or mixed)
- Returns typed `User` for user() (never null or mixed)
- Throws `AuthenticationException` when user not authenticated
- Inject via constructor in Actions/Services using `private readonly`
- Don't use in Controllers (middleware + request helpers are better)
- Easily mockable for testing
- Eliminates repeated auth validation code
- Satisfies static analysis tools (PHPStan, Psalm)

## Related

- `SERVICE-001-actions` - Action pattern using AuthService
- `AUTH-002-api` - API authentication setup
- `HTTP-002-form-requests` - Form requests have $this->user() helper
