# TEST-001-feature-tests

## Pattern

End-to-end API tests using modern PHP 8+ attributes and data providers.

## Structure

```php
<?php

declare(strict_types=1);

namespace Modules\{Module}\Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Modules\{Module}\Http\Controllers\{Model}Controller;
use Modules\{Module}\Models\{Model};
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Group;
use PHPUnit\Framework\Attributes\TestDox;
use Tests\TestCase;

#[CoversClass({Model}Controller::class)]
#[Group('{module}')]
#[Group('{module}-actions')]
class Create{Model}Test extends TestCase
{
    use RefreshDatabase;

    #[TestDox('Successfully creates a {model} with valid data')]
    public function testCreates{Model}Successfully(): void
    {
        $user = $this->actingAsUser();

        $response = $this->postJson(route('{module}.store'), [
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

        $response = $this->postJson(route('{module}.store'), $data);

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
        $response = $this->postJson(route('{module}.store'), [
            'name' => 'Test Name',
        ]);

        $response->assertStatus(401);
    }
}
```

## Testing Events

```php
use Illuminate\Support\Facades\Event;
use Modules\{Module}\Events\{Model}Created;

#[TestDox('Dispatches {Model}Created event when {model} is created')]
public function testDispatches{Model}CreatedEvent(): void
{
    Event::fake();

    $user = $this->actingAsUser();

    $this->postJson(route('{module}.store'), [
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
    $response = $this->postJson(route('{module}.store'), [
        'name' => 'Test Name',
    ]);

    $response->assertStatus(422)
        ->assertJsonValidationErrors(['name']);
}
```

## Testing Query Builder (Spatie) Endpoints

When using `spatie/laravel-query-builder` for list endpoints, test filters, sorts, includes, and their combinations.

### Testing Filters

#### Valid Filter Parameters

Test that allowed filters work correctly using data providers:

```php
#[TestDox('Filters by $filterName')]
#[DataProvider('validFiltersProvider')]
public function testFiltersByAllowedField(string $filterName, array $filterValue, int $expectedCount): void
{
    $user = $this->actingAsUser();

    // Create test data
    Household::factory()->forUser($user)->withName('Kitchen Budget')->create();
    Household::factory()->forUser($user)->withName('Living Room')->create();

    $response = $this->getJson(route('api.household.index', [
        'filter' => [$filterName => $filterValue],
    ]));

    $response->assertStatus(200)
        ->assertJsonCount($expectedCount, 'data');
}

/**
 * @return array<string, array{filterName: string, filterValue: array<string, mixed>, expectedCount: int}>
 */
public static function validFiltersProvider(): array
{
    return [
        'name partial match' => [
            'filterName' => 'name',
            'filterValue' => ['Kitchen'],
            'expectedCount' => 1,
        ],
        'is_active true' => [
            'filterName' => 'is_active',
            'filterValue' => [true],
            'expectedCount' => 2,
        ],
    ];
}
```

#### Specific Filter Tests

For important filters, write dedicated tests with clear assertions:

```php
#[TestDox('Filters by partial name match')]
public function testFiltersByPartialName(): void
{
    $user = $this->actingAsUser();
    Household::factory()->forUser($user)->withName('Kitchen Budget')->create();
    Household::factory()->forUser($user)->withName('Living Room')->create();

    $response = $this->getJson(route('api.household.index', [
        'filter' => ['name' => 'Kitchen'],
    ]));

    $response->assertStatus(200)
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.name', 'Kitchen Budget');
}
```

#### Disallowed Filters

Test that filters not in the allowedFilters list are rejected:

```php
#[TestDox('Rejects disallowed filter: $filterName')]
#[DataProvider('disallowedFiltersProvider')]
public function testRejectsDisallowedFilter(string $filterName): void
{
    $this->actingAsUser();

    $response = $this->getJson(route('api.household.index', [
        'filter' => [$filterName => 'value'],
    ]));

    $response->assertStatus(400);
}

/**
 * @return array<string, array{filterName: string}>
 */
public static function disallowedFiltersProvider(): array
{
    return [
        'owner_id' => ['owner_id'],
        'internal_field' => ['internal_field'],
        'nonexistent' => ['nonexistent'],
    ];
}
```

### Testing Sorts

#### Valid Sort Parameters

Test ascending and descending sorts with a data provider:

```php
#[TestDox('Sorts by $sortField')]
#[DataProvider('validSortsProvider')]
public function testSortsByField(string $sortParam, string $expectedFirst, string $expectedLast): void
{
    $user = $this->actingAsUser();

    // Create data in specific order
    Household::factory()->forUser($user)->withName('Gamma')->create();
    Household::factory()->forUser($user)->withName('Alpha')->create();
    Household::factory()->forUser($user)->withName('Beta')->create();

    $response = $this->getJson(route('api.household.index', [
        'sort' => $sortParam,
    ]));

    $response->assertStatus(200)
        ->assertJsonPath('data.0.name', $expectedFirst)
        ->assertJsonPath('data.2.name', $expectedLast);
}

/**
 * @return array<string, array{sortParam: string, expectedFirst: string, expectedLast: string}>
 */
public static function validSortsProvider(): array
{
    return [
        'name ascending' => ['name', 'Alpha', 'Gamma'],
        'name descending' => ['-name', 'Gamma', 'Alpha'],
        'created_at ascending' => ['created_at', 'Alpha', 'Gamma'],
        'created_at descending' => ['-created_at', 'Gamma', 'Alpha'],
    ];
}
```

#### Disallowed Sorts

Test that sorts not in the allowedSorts list are rejected:

```php
#[TestDox('Rejects disallowed sort: $sortField')]
#[DataProvider('disallowedSortsProvider')]
public function testRejectsDisallowedSort(string $sortField): void
{
    $this->actingAsUser();

    $response = $this->getJson(route('api.household.index', [
        'sort' => $sortField,
    ]));

    $response->assertStatus(400);
}

/**
 * @return array<string, array{sortField: string}>
 */
public static function disallowedSortsProvider(): array
{
    return [
        'owner_id ascending' => ['owner_id'],
        'owner_id descending' => ['-owner_id'],
        'password ascending' => ['password'],
        'nonexistent' => ['nonexistent'],
    ];
}
```

### Testing Includes

#### Valid Relationship Includes

Test that allowed relationship includes are loaded:

```php
#[TestDox('Includes $relationship relationship')]
#[DataProvider('validIncludesProvider')]
public function testIncludesRelationship(string $relationship, string $expectedKey): void
{
    $user = $this->actingAsUser();
    $household = Household::factory()->forUser($user)->create();

    // Create related data if needed
    if ($relationship === 'members') {
        HouseholdMember::factory()->forHousehold($household)->count(2)->create();
    }

    $response = $this->getJson(route('api.household.index', [
        'include' => $relationship,
    ]));

    $response->assertStatus(200)
        ->assertJsonStructure([
            'data' => [
                '*' => [$expectedKey],
            ],
        ]);
}

/**
 * @return array<string, array{relationship: string, expectedKey: string}>
 */
public static function validIncludesProvider(): array
{
    return [
        'owner' => ['owner', 'owner'],
        'members' => ['members', 'members'],
    ];
}
```

#### Specific Include Tests

For complex relationships, write dedicated tests:

```php
#[TestDox('Includes members relationship with correct structure')]
public function testIncludesMembersWithCorrectStructure(): void
{
    $user = $this->actingAsUser();
    $household = Household::factory()->forUser($user)->create();
    HouseholdMember::factory()->forHousehold($household)->count(2)->create();

    $response = $this->getJson(route('api.household.index', [
        'include' => 'members',
    ]));

    $response->assertStatus(200)
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'members' => [
                        '*' => [
                            'id',
                            'user_id',
                            'status',
                        ],
                    ],
                ],
            ],
        ]);
}
```

#### Disallowed Includes

Test that includes not in the allowedIncludes list are rejected:

```php
#[TestDox('Rejects disallowed include: $includeName')]
#[DataProvider('disallowedIncludesProvider')]
public function testRejectsDisallowedInclude(string $includeName): void
{
    $this->actingAsUser();

    $response = $this->getJson(route('api.household.index', [
        'include' => $includeName,
    ]));

    $response->assertStatus(400);
}

/**
 * @return array<string, array{includeName: string}>
 */
public static function disallowedIncludesProvider(): array
{
    return [
        'deleted_items' => ['deleted_items'],
        'internal_logs' => ['internal_logs'],
        'nonexistent' => ['nonexistent'],
    ];
}
```

### Testing Combined Parameters

Test filter, sort, and include working together:

```php
#[TestDox('Combines filter, sort, and include parameters')]
public function testCombinesFilterSortAndInclude(): void
{
    $user = $this->actingAsUser();

    // Create test data
    $active1 = Household::factory()->forUser($user)
        ->withName('Alpha Active')
        ->active()
        ->create();
    $active2 = Household::factory()->forUser($user)
        ->withName('Beta Active')
        ->active()
        ->create();
    $inactive = Household::factory()->forUser($user)
        ->withName('Gamma Inactive')
        ->inactive()
        ->create();

    HouseholdMember::factory()->forHousehold($active1)->count(2)->create();
    HouseholdMember::factory()->forHousehold($active2)->count(3)->create();

    $response = $this->getJson(route('api.household.index', [
        'filter' => ['is_active' => true],
        'sort' => 'name',
        'include' => 'members',
    ]));

    $response->assertStatus(200)
        ->assertJsonCount(2, 'data')
        ->assertJsonPath('data.0.name', 'Alpha Active')
        ->assertJsonPath('data.1.name', 'Beta Active')
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'is_active',
                    'members',
                ],
            ],
        ]);
}
```

### Key Patterns

**Query Builder Test Checklist:**
- Valid filters return 200 and correct data
- Disallowed filters return 400
- Valid sorts return 200 with correct order (test both asc and desc)
- Disallowed sorts return 400
- Valid includes return 200 with relationship data
- Disallowed includes return 400
- Combined parameters work together correctly

**Assertions:**
- Use `assertJsonStructure()` to verify response shape
- Use `assertJsonPath()` to verify specific values
- Use `assertJsonCount()` to verify result counts
- Use `assertStatus(200)` for valid parameters
- Use `assertStatus(400)` for disallowed parameters

**Data Providers:**
- Group related test cases with data providers
- Use descriptive keys for each test case
- Include both positive and negative cases
- Document expected behavior in provider keys

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
- `{Action}{Model}Test.php` - e.g., `CreateHouseholdTest.php`, `UpdateHouseholdTest.php`
- One test class per action/endpoint

**Reusable Test Helpers:**
- If creating multiple related tests with shared setup, see `TRAIT-002-test-traits`
- Extract helpers to `tests/Concerns/InteractsWith{Domain}.php` when used in 3+ test classes

## Related

- `TEST-002-unit-tests` - Unit test patterns
- `TRAIT-002-test-traits` - Reusable test helper traits
