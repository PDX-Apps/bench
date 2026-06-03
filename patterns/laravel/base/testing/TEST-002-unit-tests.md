# TEST-002-unit-tests

## Pattern

Tests that call code directly (not through HTTP). Test **behavior**, not implementation.

**Unit tests call Actions/Services directly. Feature tests go through HTTP.**

Unit tests can use the database when needed - that doesn't make them Feature tests.

## Instantiation: Never Use app->make()

**Always instantiate the class under test directly with mocked dependencies:**

```php
// ❌ NEVER do this in unit tests
protected function setUp(): void
{
    parent::setUp();
    $this->action = $this->app->make(SomeAction::class);
}

// ✅ ALWAYS instantiate directly with mocked dependencies
protected function setUp(): void
{
    parent::setUp();
    $this->mockService = $this->createMock(SomeService::class);
    $this->action = new SomeAction($this->mockService);
}
```

This applies even when using `RefreshDatabase`. The database is for unmockable queries (Builder calls, `Model::create()` inside the method). Injected dependencies are still mocked.

## Philosophy

### Test Behavior, Not Implementation

```php
// ❌ BAD - Tests implementation details
public function testAcceptSetsAcceptedAt(): void
{
    $invitation = new HouseholdInvitation();
    $invitation->accept();

    // Testing internal property - will break if we rename the field
    $this->assertNotNull($invitation->accepted_at);
}

// ✅ GOOD - Tests behavior/outcome
public function testAcceptChangesStatusToAccepted(): void
{
    $invitation = new HouseholdInvitation();
    $invitation->accept();

    // Tests observable behavior via public API
    $this->assertEquals(InvitationStatus::Accepted, $invitation->status);
    $this->assertFalse($invitation->isPending());
}
```

### Never Test Private Methods Directly

Private methods are implementation details. If a private method is complex enough to need direct testing, **extract it to its own class**.

```php
// ❌ BAD - Using reflection to test private method
public function testCalculateDiscount(): void
{
    $reflection = new ReflectionMethod(Order::class, 'calculateDiscount');
    $reflection->setAccessible(true);
    // ...
}

// ✅ GOOD - Extract to testable class if complex
class DiscountCalculator
{
    public function calculate(Order $order): Money
    {
        // Now this is public and testable
    }
}
```

## When to Use Unit vs Feature Tests

| Component | Unit Test | Feature Test | Reason |
|-----------|-----------|--------------|--------|
| Controllers | ❌ | ✅ | Thin, HTTP concerns only |
| FormRequests | ❌ | ✅ | Validation via HTTP |
| Actions | ✅ | ✅ | Unit for orchestration, Feature for integration |
| Models (domain methods) | ✅ | ❌ | Pure state logic, no DB needed |
| Models (relationships) | ❌ | ✅ | Needs database |
| Models (scopes) | ❌ | ✅ | Needs database |
| Policies | ✅ | ✅ | Can be isolated |
| Events | ✅ | ❌ | Data containers |
| Value Objects / DTOs | ✅ | ❌ | Pure logic |
| Services (pure logic) | ✅ | ❌ | No external dependencies |

### Unit vs Feature: The Real Distinction

**The distinction is HTTP, not database.**

| Test Type | Calls | Database | HTTP |
|-----------|-------|----------|------|
| Unit (mocked) | `$action->execute(...)` | ❌ Mocked | ❌ |
| Unit (with DB) | `$action->execute(...)` | ✅ Real | ❌ |
| Feature | `$this->postJson(...)` | ✅ Real | ✅ |

**Unit tests** - Call Actions/Services directly:
- Can mock dependencies OR use real database
- Test business logic, orchestration, events
- Faster than Feature tests (no HTTP overhead)

**Feature tests** - Go through HTTP layer:
- Test full request/response cycle
- Test controllers, middleware, auth
- Test API contracts

### Example: Testing an Action

```php
// UpdateHouseholdAction.php
public function execute(Household $household, HouseholdData $data): Household
{
    $household->update(['name' => $data->name]);
    event(new HouseholdUpdated($household, $household->getChanges()));
    return $household;
}
```

**Unit test - verify orchestration:**
```php
public function testUpdatesHouseholdWithCorrectData(): void
{
    Event::fake();

    $household = $this->createMock(Household::class);
    $household->expects($this->once())
        ->method('update')
        ->with(['name' => 'New Name']);
    $household->method('getChanges')->willReturn(['name' => 'New Name']);

    $action = new UpdateHouseholdAction();
    $action->execute($household, new HouseholdData(name: 'New Name'));
}

public function testDispatchesEventWithChanges(): void
{
    Event::fake();

    $household = $this->createHouseholdStub();
    $household->method('getChanges')->willReturn(['name' => 'New Name']);

    $action = new UpdateHouseholdAction();
    $action->execute($household, new HouseholdData(name: 'New Name'));

    Event::assertDispatched(HouseholdUpdated::class, fn($event) =>
        $event->changes === ['name' => 'New Name']
    );
}
```

**Unit test with database** (when the Action has unmockable DB queries inside):
```php
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\MockObject\MockObject;

class JoinHouseholdActionTest extends TestCase
{
    use RefreshDatabase;

    private MockObject $notificationService;
    private JoinHouseholdAction $action;

    protected function setUp(): void
    {
        parent::setUp();

        // Still mock injected dependencies - RefreshDatabase doesn't change this
        $this->notificationService = $this->createMock(NotificationService::class);
        $this->action = new JoinHouseholdAction($this->notificationService);
    }

    public function testThrowsWhenHouseholdNotFound(): void
    {
        // Real DB needed because Action does: Household::query()->where('code', ...)->firstOrFail()
        $user = User::factory()->create();

        $this->expectException(ValidationException::class);

        $this->action->execute('INVALID_CODE', $user);
    }

    public function testAutoAcceptsExistingInvitation(): void
    {
        Event::fake();

        // Real DB for the unmockable queries inside the Action
        $household = Household::factory()->create(['code' => 'ABC123']);
        $user = User::factory()->create();
        HouseholdInvitation::factory()->create([
            'household_id' => $household->id,
            'invitee_id' => $user->id,
        ]);

        // But we can still verify mocked dependencies are called correctly
        $this->notificationService->expects($this->once())
            ->method('sendWelcome')
            ->with($user);

        $result = $this->action->execute('ABC123', $user);

        $this->assertEquals('joined', $result['status']);
        Event::assertDispatched(InvitationAccepted::class);
    }
}
```

**Key point:** RefreshDatabase is for unmockable DB calls inside the Action. You still mock all injected dependencies.

**Feature test** (through HTTP):
```php
public function testUpdatesHouseholdInDatabase(): void
{
    $household = Household::factory()->create(['name' => 'Old Name']);

    $this->putJson(route('household.update', $household), ['name' => 'New Name'])
        ->assertOk();

    $this->assertDatabaseHas('households', [
        'id' => $household->id,
        'name' => 'New Name',
    ]);
}
```

### When to Use RefreshDatabase

**Use RefreshDatabase when the code under test has unmockable DB calls:**
- `Model::query()->where(...)->get()` (Builder/query calls)
- `Model::create([...])` or `new Model(); $model->save()` inside the method
- Relationship queries (`$model->relatedItems()->create(...)`)

**Even with RefreshDatabase, you still mock injected dependencies:**

```php
use Illuminate\Foundation\Testing\RefreshDatabase;

class CreateOrderActionTest extends TestCase
{
    use RefreshDatabase; // For unmockable Order::create() inside the Action

    private MockObject $paymentService;
    private MockObject $inventoryService;
    private CreateOrderAction $action;

    protected function setUp(): void
    {
        parent::setUp();

        // Mock all injected dependencies
        $this->paymentService = $this->createMock(PaymentService::class);
        $this->inventoryService = $this->createMock(InventoryService::class);
        $this->action = new CreateOrderAction(
            $this->paymentService,
            $this->inventoryService,
        );
    }

    public function testCreatesOrderAndChargesPayment(): void
    {
        $user = User::factory()->create();
        $product = Product::factory()->create(['price' => 1000]);

        // Verify mocked dependency is called correctly
        $this->paymentService->expects($this->once())
            ->method('charge')
            ->with($user, 1000);

        $this->inventoryService->expects($this->once())
            ->method('reserve')
            ->with($product->id, 1);

        $order = $this->action->execute($user, new OrderData(
            productId: $product->id,
            quantity: 1,
        ));

        // Assert DB state for the unmockable Model::create()
        $this->assertDatabaseHas('orders', [
            'id' => $order->id,
            'user_id' => $user->id,
        ]);
    }
}
```

| Concern | What to do |
|---------|------------|
| RefreshDatabase | Only for unmockable DB calls (Builder, Model::create) |
| Injected dependencies | Always mock them |
| Instantiation | Always `new ActionClass($mock1, $mock2)`, never `app->make()`|

**Use mocking for:**
- All injected project classes (Services, other Actions)
- External services (APIs, payment gateways, email)
- Expensive operations you want to skip
  cted $filla
## PHPUnit 12 Attributes

Use PHP 8 attributes (not docblock annotations):

```php
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Depends;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\Test;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\Attributes\TestWith;
```

| Attribute | Purpose |
|-----------|---------|
| `#[CoversClass(Class::class)]` | Code coverage mapping |
| `#[Group('name')]` | Test grouping for filtering |
| `#[TestDox('Description')]` | Human-readable test output |
| `#[DataProvider('methodName')]` | Parameterized tests |
| `#[TestWith([1, 2, 3])]` | Inline test data |
| `#[Depends('testMethodName')]` | Test dependencies |
| `#[Test]` | Mark method as test (alternative to `test*` prefix) |

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Tests\Unit\Models;

use Modules\{Module}\Exceptions\InvalidStateException;
use Modules\{Module}\Models\{Model};
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversClass({Model}::class)]
#[Group('{module}')]
#[Group('{module}-models')]
class {Model}Test extends TestCase
{
    #[TestDox('Can transition from pending to accepted state')]
    public function testCanAcceptPendingInvitation(): void
    {
        $model = new {Model}();

        $model->accept();

        $this->assertEquals(Status::Accepted, $model->status);
    }

    #[TestDox('Throws exception when accepting non-pending invitation')]
    public function testCannotAcceptNonPendingInvitation(): void
    {
        $model = new {Model}();
        $model->accepted_at = now();

        $this->expectException(InvalidStateException::class);
        $this->expectExceptionMessage('already been accepted');

        $model->accept();
    }

    #[TestDox('Validates status transitions: $currentStatus -> $newStatus')]
    #[DataProvider('statusTransitionProvider')]
    public function testStatusTransitions(string $currentStatus, string $newStatus, bool $shouldSucceed): void
    {
        // Parameterized test
    }

    /**
     * @return array<string, array{currentStatus: string, newStatus: string, shouldSucceed: bool}>
     */
    public static function statusTransitionProvider(): array
    {
        return [
            'pending to accepted' => ['pending', 'accepted', true],
            'pending to denied' => ['pending', 'denied', true],
            'accepted to denied' => ['accepted', 'denied', false],
        ];
    }
}
```

## Testing Domain Methods

Domain methods (MODEL-003) should be unit tested in isolation:

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Tests\Unit\Models;

use Modules\Household\Enums\InvitationStatus;
use Modules\Household\Exceptions\InvitationAlreadyProcessedException;
use Modules\Household\Models\HouseholdInvitation;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversClass(HouseholdInvitation::class)]
class HouseholdInvitationTest extends TestCase
{
    #[TestDox('accept() changes status to accepted')]
    public function testAcceptChangesStatusToAccepted(): void
    {
        $invitation = new HouseholdInvitation();

        $invitation->accept();

        $this->assertEquals(InvitationStatus::Accepted, $invitation->status);
        $this->assertFalse($invitation->isPending());
    }

    #[TestDox('accept() throws when already accepted')]
    public function testAcceptThrowsWhenAlreadyAccepted(): void
    {
        $invitation = new HouseholdInvitation();
        $invitation->accepted_at = now();

        $this->expectException(InvitationAlreadyProcessedException::class);

        $invitation->accept();
    }

    #[TestDox('accept() throws when already denied')]
    public function testAcceptThrowsWhenAlreadyDenied(): void
    {
        $invitation = new HouseholdInvitation();
        $invitation->denied_at = now();

        $this->expectException(InvitationAlreadyProcessedException::class);

        $invitation->accept();
    }

    #[TestDox('deny() changes status to denied')]
    public function testDenyChangesStatusToDenied(): void
    {
        $invitation = new HouseholdInvitation();

        $invitation->deny();

        $this->assertEquals(InvitationStatus::Denied, $invitation->status);
        $this->assertFalse($invitation->isPending());
    }

    #[TestDox('isPending() returns true for new invitation')]
    public function testIsPendingReturnsTrueForNewInvitation(): void
    {
        $invitation = new HouseholdInvitation();

        $this->assertTrue($invitation->isPending());
    }
}
```

## Testing Actions with Mocks

Unit test Actions by mocking external dependencies:

```php
<?php

declare(strict_types=1);

namespace Modules\Household\Tests\Unit\Actions;

use App\Services\AuthService;
use Illuminate\Validation\ValidationException;
use Modules\Household\Actions\InviteMemberAction;
use Modules\Household\Data\InviteMemberData;
use Modules\Household\Models\Household;
use Modules\Household\Models\HouseholdInvitation;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversClass(InviteMemberAction::class)]
class InviteMemberActionTest extends TestCase
{
    #[TestDox('Throws when user invites themselves')]
    public function testThrowsWhenUserInvitesThemselves(): void
    {
        $authService = $this->createMock(AuthService::class);
        $authService->method('userId')->willReturn(1);

        $action = new InviteMemberAction($authService);

        $household = $this->createMock(Household::class);
        $data = new InviteMemberData(inviteeId: 1); // Same as auth user

        $this->expectException(ValidationException::class);

        $action->execute($household, $data);
    }
}
```

## Mocking Strategy (PHPUnit 12)

### Stubs vs Mocks

**Stubs** - Configure return values only (no verification):
```php
$stub = $this->createStub(AuthService::class);
$stub->method('userId')->willReturn(1);
```

**Mocks** - Verify method calls + configure returns:
```php
$mock = $this->createMock(AuthService::class);
$mock->expects($this->once())
    ->method('userId')
    ->willReturn(1);
```

**Rule:** Use `createStub()` when you only need return values. Use `createMock()` when you need to verify calls.

### Configuring Return Values

```php
// Fixed return
$stub->method('find')->willReturn($entity);

// Sequential returns (different value each call)
$stub->method('getNext')->willReturn('first', 'second', 'third');

// Throw exception
$stub->method('validate')->willThrowException(new InvalidException());

// Return argument unchanged
$stub->method('process')->willReturnArgument(0);

// Custom callback
$stub->method('calculate')->willReturnCallback(fn($x) => $x * 2);

// Fluent interfaces (return $this)
$stub->method('withOption')->willReturnSelf();
```

### Verifying Method Calls

```php
// Called exactly once
$mock->expects($this->once())->method('save');

// Never called
$mock->expects($this->never())->method('delete');

// Called at least once
$mock->expects($this->atLeastOnce())->method('log');

// Called exactly N times
$mock->expects($this->exactly(3))->method('retry');

// With specific arguments
$mock->expects($this->once())
    ->method('update')
    ->with($this->identicalTo($entity));
```

### Mock External Dependencies, Not Internals

```php
// ✅ Mock external services
$authService = $this->createStub(AuthService::class);
$authService->method('userId')->willReturn(1);

// ✅ Mock repositories/database access
$repository = $this->createStub(UserRepository::class);
$repository->method('find')->willReturn($user);

// ❌ Don't mock the class you're testing
$invitation = $this->createMock(HouseholdInvitation::class); // BAD

// ❌ Don't mock value objects or DTOs
$data = $this->createMock(InviteMemberData::class); // BAD - just instantiate it
```

### Mocking Eloquent Models

When mocking models with magic `__get` properties:

```php
$invitation = $this->createMock(HouseholdInvitation::class);

$invitation->method('__get')
    ->willReturnCallback(fn($prop) => match ($prop) {
        'id' => 1,
        'household_id' => 1,
        'status' => InvitationStatus::Pending,
        default => null,
    });
```

### When NOT to Mock

- The class under test
- Value Objects and DTOs
- Simple data structures
- Pure functions
- Interfaces over classes (prefer doubling interfaces)

## Directory Structure

```
Modules/{Module}/tests/
├── Feature/                        # HTTP/Integration tests
│   ├── CreateEntityTest.php        # One per endpoint/action
│   ├── UpdateEntityTest.php
│   └── ...
└── Unit/                           # Isolated logic tests
    ├── Models/
    │   └── EntityTest.php          # Test domain methods
    ├── Actions/
    │   └── CreateEntityActionTest.php
    └── Services/
        └── CalculatorServiceTest.php
```

For app-level:
```
tests/
├── Feature/
└── Unit/
    ├── Models/
    ├── Services/
    └── ...
```

## Design for Testability

To use `PHPUnit\Framework\TestCase` (fast, no Laravel boot), code must follow these rules:

### Required: Explicit Dependency Injection

```php
// ❌ CANNOT unit test - requires Laravel container
class BadAction
{
    public function execute(): void
    {
        $service = app(SomeService::class);  // Service location
        $userId = auth()->id();               // Helper function
    }
}

// ✅ CAN unit test - explicit DI
class GoodAction
{
    public function __construct(
        private readonly SomeService $service,
        private readonly AuthService $auth,
    ) {}

    public function execute(): void
    {
        $userId = $this->auth->userId();
    }
}
```

### Required: No Request-Scoped Dependencies

For Octane safety and testability, Actions/Services must be stateless:

```php
// ❌ CANNOT unit test - request-scoped dependency
class BadAction
{
    public function __construct(
        private readonly SessionManager $session, // Stale in Octane!
    ) {}
}

// ✅ CAN unit test - receives data as params
class GoodAction
{
    public function execute(array $cartItems): CartResult
    {
        // Pure business logic, no session access
    }
}
```

### Dependency Injection Rules

| Dependency | Inject? | Unit Testable? | Notes |
|-----------|---------|----------------|-------|
| AuthService | ✅ Yes | ✅ Mock it | Designed for safe DI |
| Other Actions | ✅ Yes | ✅ Mock it | Stateless |
| Pure Services | ✅ Yes | ✅ Mock it | Calculators, validators |
| Session | ❌ No | ❌ | Pass data as params |
| Request | ❌ No | ❌ | Pass data as params |
| `app()` / `resolve()` | ❌ No | ❌ | Use constructor DI |

### Choosing the Right TestCase

Use the appropriate TestCase based on what your code depends on:

**Use `PHPUnit\Framework\TestCase` when code:**
- Has no Laravel dependencies
- Pure domain methods on models
- Value Objects, DTOs
- Pure calculation/validation services

```php
use PHPUnit\Framework\TestCase;

class HouseholdInvitationTest extends TestCase
{
    public function testAcceptChangesStatus(): void
    {
        $invitation = new HouseholdInvitation();
        $invitation->accept();
        // Pure domain logic - no Laravel needed
    }
}
```

**Use `Tests\TestCase` (Laravel boot, no DB) when code uses:**
- `ValidationException::withMessages()` (common for consistent UI errors)
- `event()` helper or Event facade
- Any Laravel facades or helpers
- Service container resolution

```php
use Tests\TestCase;

class AcceptInvitationActionTest extends TestCase
{
    public function testThrowsValidationExceptionWhenAlreadyAccepted(): void
    {
        // Action uses ValidationException::withMessages() internally
        // which requires Laravel's translator
    }
}
```

**Use `Tests\TestCase` with `RefreshDatabase` when code needs:**
- Database queries
- Eloquent relationships
- Query scopes
- `save()`, `fresh()`, `create()`

```php
use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;

class CreateInvitationTest extends TestCase
{
    use RefreshDatabase;
}
```

**Rule of thumb:** Match the TestCase to your code's dependencies. Don't force PHPUnit\Framework\TestCase if your code legitimately uses Laravel utilities like `ValidationException::withMessages()`.

## Key Points

**What to Unit Test:**
- Domain methods on Models (state transitions, calculations)
- Actions with complex business rules (mock dependencies)
- Value Objects and DTOs (validation, transformation)
- Services with pure logic
- Event data integrity

**What NOT to Unit Test:**
- Controllers (use Feature tests)
- Eloquent relationships (need database)
- Query scopes (need database)
- Simple getters/setters
- Framework code

**Testing Principles:**
- Test behavior/outcomes, not implementation details
- Never test private methods directly
- If private method needs testing, extract to own class
- Mock external dependencies, not internals
- One assertion concept per test (can have multiple asserts for same concept)
- Choose TestCase based on code dependencies (see "Choosing the Right TestCase")

**Design Principles (for testability):**
- Explicit constructor DI, no `app()` or `resolve()`
- No request-scoped dependencies (Session, Request)
- Use AuthService instead of `auth()` helper
- Stateless Actions/Services - receive data as params

**Naming:**
- Test class: `{ClassName}Test.php`
- Test method: `test{Behavior}` with `#[TestDox]` for description
- Group by component type: `Models/`, `Actions/`, `Services/`

**Reusable Test Helpers:**
- If creating multiple related tests with shared mock/stub setup, see `TRAIT-002-test-traits`
- Extract helpers to `tests/Concerns/InteractsWith{Domain}.php` when used in 3+ test classes

## Related

- `TEST-001-feature-tests` - HTTP/API tests
- `TRAIT-002-test-traits` - Reusable test helper traits
- `MODEL-003-domain-methods` - Domain methods to test
- `SERVICE-001-actions` - Actions to test (includes Octane-safe design)
