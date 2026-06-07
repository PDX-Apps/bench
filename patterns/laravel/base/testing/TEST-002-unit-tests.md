# TEST-002-unit-tests

## Pattern

Tests that call code directly (not through HTTP). Test **behavior**, not implementation.

**Unit tests call Actions/Services/domain methods directly. Feature tests go through HTTP.** A
unit test may still touch the database — that doesn't make it a feature test. The distinction is
**HTTP, not database**.

| Test type | Calls | Database | HTTP |
|-----------|-------|----------|------|
| Unit (mocked) | `$action->execute(...)` | mocked | ❌ |
| Unit (with DB) | `$action->execute(...)` | real | ❌ |
| Feature | `$this->postJson(...)` | real | ✅ |

## Instantiation: Never `app()->make()`

Instantiate the class under test directly with mocked dependencies — even when using
`RefreshDatabase`. The database is for unmockable queries inside the method; injected
dependencies are still mocked.

```php
// ❌ NEVER in a unit test
$this->action = $this->app->make(CreateOrderAction::class);

// ✅ instantiate directly with mocked dependencies
$this->pricing = $this->createMock(PricingCalculator::class);
$this->action = new CreateOrderAction($this->pricing);
```

## Test Behavior, Not Implementation

```php
// ❌ BAD - asserts an internal field (breaks on rename)
$invitation->accept();
$this->assertNotNull($invitation->accepted_at);

// ✅ GOOD - asserts observable behavior via the public API
$invitation->accept();
$this->assertSame(InvitationStatus::Accepted, $invitation->status());
$this->assertFalse($invitation->isPending());
```

Never test private methods directly. If a private method is complex enough to need its own
test, extract it to its own class.

## Authenticated User: a Param, Not a Mocked Service

Actions receive the authenticated `User` as an `execute()` parameter (the controller passes
`$request->user()` in) — they don't pull it from global state. So unit tests pass a `User`
directly; there's no auth service to mock.

```php
public function execute(User $user, CreateOrderData $data): Order { /* ... */ }

// Test — pass a User in
$user = User::factory()->make();              // or ->create() if the method queries the DB
$action->execute($user, new CreateOrderData(...));
```

Mock the **Services and other Actions** the class injects — not the User, and never the class
under test, DTOs, or value objects.

## Testing a Domain Method (no Laravel boot)

Pure domain methods need only `PHPUnit\Framework\TestCase`:

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Models;

use App\Enums\InvitationStatus;
use App\Exceptions\InvitationAlreadyProcessedException;
use App\Models\Invitation;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversClass(Invitation::class)]
class InvitationTest extends TestCase
{
    #[TestDox('accept() changes status to accepted')]
    public function testAcceptChangesStatus(): void
    {
        $invitation = new Invitation();

        $invitation->accept();

        $this->assertSame(InvitationStatus::Accepted, $invitation->status());
        $this->assertFalse($invitation->isPending());
    }

    #[TestDox('accept() throws when already processed')]
    public function testAcceptThrowsWhenAlreadyAccepted(): void
    {
        $invitation = new Invitation();
        $invitation->accepted_at = now();

        $this->expectException(InvitationAlreadyProcessedException::class);

        $invitation->accept();
    }
}
```

## Testing an Action with Mocked Dependencies

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\CreateOrderAction;
use App\Data\CreateOrderData;
use App\Models\User;
use App\Services\PricingCalculator;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\CoversClass;
use Tests\TestCase;

#[CoversClass(CreateOrderAction::class)]
class CreateOrderActionTest extends TestCase
{
    use RefreshDatabase; // the Action runs Order::create() internally — unmockable

    public function testCreatesOrderAndChargesPayment(): void
    {
        $user = User::factory()->create();

        $pricing = $this->createMock(PricingCalculator::class);
        $pricing->expects($this->once())
            ->method('breakdown')
            ->willReturn(['subtotal' => 1000, 'tax' => 80, 'total' => 1080]);

        $action = new CreateOrderAction($pricing);
        $order = $action->execute($user, new CreateOrderData(subtotalCents: 1000, taxRate: 0.08));

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'user_id' => $user->id]);
    }
}
```

`RefreshDatabase` is only for unmockable DB calls inside the method (`Model::create()`, Builder
queries, relationship writes). You still mock every injected dependency.

## Mocking Strategy (PHPUnit)

- **Stub** (`createStub`) when you only need return values; **mock** (`createMock`) when you
  also verify calls (`expects($this->once())`).
- Mock external/injected collaborators (Services, other Actions, API clients).
- **Don't** mock the class under test, DTOs/value objects, or simple data structures — construct them.

```php
$stub = $this->createStub(CurrencyConverter::class);
$stub->method('toCents')->willReturn(1000);

$mock = $this->createMock(NotificationDispatcher::class);
$mock->expects($this->once())->method('send');
```

## PHPUnit 12 Attributes

Use attributes, not docblock annotations:

```php
use PHPUnit\Framework\Attributes\CoversClass;   // coverage mapping
use PHPUnit\Framework\Attributes\DataProvider;  // parameterized tests
use PHPUnit\Framework\Attributes\Group;         // filtering
use PHPUnit\Framework\Attributes\TestDox;       // human-readable output
```

## Choosing the Right TestCase

Match the base class to what the code depends on:

- **`PHPUnit\Framework\TestCase`** — pure domain methods, DTOs, value objects, pure services. No Laravel boot, fastest.
- **`Tests\TestCase`** — code that uses Laravel utilities (`ValidationException::withMessages()`, `event()`, facades, container).
- **`Tests\TestCase` + `RefreshDatabase`** — code that queries the database, uses relationships/scopes, or persists.

## Design for Testability

For code to be unit-testable (ideally on the plain PHPUnit `TestCase`):

- **Explicit constructor DI** — no `app()` / `resolve()` / service location inside methods.
- **No request-scoped or global state** — receive the `User` and other data as parameters; never reach for `auth()`, `request()`, or the session. (Also keeps Actions Octane-safe.)
- **Stateless** Actions/Services.

```php
// ❌ can't unit test without the container / a request
class BadAction
{
    public function execute(): void
    {
        $service = app(SomeService::class);
        $userId = auth()->id();
    }
}

// ✅ unit-testable — everything injected or passed in
class GoodAction
{
    public function __construct(private readonly SomeService $service) {}

    public function execute(User $user, OrderData $data): Order { /* ... */ }
}
```

## Directory Structure

```
tests/
├── Feature/                 # HTTP/integration tests
└── Unit/
    ├── Models/              # domain methods
    ├── Actions/
    └── Services/
```

## Key Points

- Unit = called directly (no HTTP); may use the DB. The distinction from feature tests is HTTP, not database
- Instantiate the class under test directly (`new Action($mock)`) — never `app()->make()`
- Pass the authenticated `User` in as a param; mock injected Services/Actions; never mock the class under test, DTOs, or value objects
- `RefreshDatabase` only for unmockable DB calls inside the method
- Test behavior/outcomes via the public API, not internal fields or private methods
- PHPUnit 12 attributes (`#[CoversClass]`, `#[DataProvider]`, `#[TestDox]`)
- Choose the TestCase by the code's dependencies (plain PHPUnit → Laravel → +RefreshDatabase)
- Design for testability: explicit DI, no globals (`app()`/`auth()`/session), stateless
