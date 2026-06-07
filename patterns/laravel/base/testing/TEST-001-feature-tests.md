# TEST-001-feature-tests

## Pattern

End-to-end API tests using modern PHP 8+ attributes and data providers.

## Structure

```php
<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Http\Controllers\{Model}Controller;
use App\Models\{Model};
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\TestDox;
use Tests\TestCase;

#[CoversClass({Model}Controller::class)]
#[Group('{model}')]
#[Group('{model}-actions')]
class Create{Model}Test extends TestCase
{
    use RefreshDatabase;

    #[TestDox('Successfully creates a {model} with valid data')]
    public function testCreates{Model}Successfully(): void
    {
        $user = $this->actingAsUser();

        $response = $this->postJson(route('{models}.store'), [
            'name' => 'Test Name',
        ]);

        $response->assertStatus(201)
            ->assertJsonStructure([
                'data' => [
                    'id',
                    'name',
                    'created_at',
                    'updated_at',
                ],
            ])
            ->assertJson([
                'data' => [
                    'name' => 'Test Name',
                ],
            ]);

        $this->assertDatabaseHas('{models}', [
            'name' => 'Test Name',
            'user_id' => $user->id,
        ]);
    }

    #[TestDox('Fails validation with invalid input: $testCase')]
    #[DataProvider('invalidInputProvider')]
    public function testFailsValidationWithInvalidInput(string $testCase, array $data, array $expectedErrors): void
    {
        $this->actingAsUser();

        $response = $this->postJson(route('{models}.store'), $data);

        $response->assertStatus(422)
            ->assertJsonValidationErrors($expectedErrors);
    }

    /**
     * @return array<string, array{testCase: string, data: array<string, mixed>, expectedErrors: array<int, string>}>
     */
    public static function invalidInputProvider(): array
    {
        return [
            'missing name' => [
                'testCase' => 'missing name',
                'data' => [],
                'expectedErrors' => ['name'],
            ],
            'empty name' => [
                'testCase' => 'empty name',
                'data' => ['name' => ''],
                'expectedErrors' => ['name'],
            ],
            'name too long' => [
                'testCase' => 'name too long',
                'data' => ['name' => str_repeat('a', 256)],
                'expectedErrors' => ['name'],
            ],
        ];
    }

    #[TestDox('Returns 401 when user is not authenticated')]
    public function testReturnsUnauthorizedWhenNotAuthenticated(): void
    {
        $response = $this->postJson(route('{models}.store'), [
            'name' => 'Test Name',
        ]);

        $response->assertStatus(401);
    }
}
```

## Testing Events

```php
use App\Events\{Model}Created;
use Illuminate\Support\Facades\Event;

#[TestDox('Dispatches {Model}Created event when {model} is created')]
public function testDispatches{Model}CreatedEvent(): void
{
    Event::fake();

    $user = $this->actingAsUser();

    $this->postJson(route('{models}.store'), [
        'name' => 'Test {Model}',
    ]);

    Event::assertDispatched({Model}Created::class, function ($event) {
        return $event->{model}->name === 'Test {Model}';
    });
}
```

## Testing Unique Constraints

```php
#[TestDox('Enforces unique name per user constraint')]
public function testEnforcesUniqueNamePerUser(): void
{
    $user = $this->actingAsUser();

    // Create first instance
    {Model}::factory()->forUser($user)->create([
        'name' => 'Test Name',
    ]);

    // Attempt duplicate
    $response = $this->postJson(route('{models}.store'), [
        'name' => 'Test Name',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name']);
}
```

## Key Points

**PHPUnit 12 Attributes:**

| Attribute | Purpose |
|-----------|---------|
| `#[CoversClass(Class::class)]` | Code coverage mapping |
| `#[Group('name')]` | Test grouping for filtering |
| `#[TestDox('Description')]` | Human-readable test output |
| `#[DataProvider('methodName')]` | Parameterized tests |
| `#[TestWith([1, 2, 3])]` | Inline test data |
| `#[Depends('testMethodName')]` | Test dependencies |

**Best Practices:**
- Use `RefreshDatabase` trait for database tests
- Use `$this->actingAsUser()` helper for authentication
- Use `route()` helper instead of hardcoded URLs
- Use data providers for validation tests (DRY)
- Descriptive test method names with TestDox attributes
- Assert response status, structure, and database state
- Test both success and error cases
- Return type `void` on all test methods

**File Naming:**
- `{Action}{Model}Test.php` - e.g., `CreateOrderTest.php`, `UpdateOrderTest.php`
- One test class per action/endpoint

**Reusable Test Helpers:**
- Extract shared setup to a trait in `tests/Concerns/InteractsWith{Domain}.php` when used in 3+ test classes
