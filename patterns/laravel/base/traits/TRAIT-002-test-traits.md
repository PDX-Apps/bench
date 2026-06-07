# TRAIT-002-test-traits

## Pattern

Reusable test helper traits for creating mocks, stubs, and test fixtures. Centralizes test setup to reduce duplication and ensure consistency.

## When to Use

Create a test trait when:
- Helper methods are reused across **3+ test classes**
- Multiple tests need the same mock/stub configuration
- Test setup is complex and domain-specific

**Don't create traits for:**
- One-off helper methods (keep in test class)
- Generic assertions (PHPUnit provides these)
- Methods used by only 1-2 test classes

## Structure

```
tests/
└── Concerns/                           # Test traits
    ├── InteractsWithInvitations.php
    ├── InteractsWithTeams.php
    ├── InteractsWithOrders.php
    └── CreatesTestFixtures.php
```

## Example: Mock/Stub Trait

```php
<?php

declare(strict_types=1);

namespace Tests\Concerns;

use App\Enums\InvitationStatus;
use App\Enums\InvitationType;
use App\Models\Invitation;
use PHPUnit\Framework\MockObject\MockObject;
use PHPUnit\Framework\MockObject\Stub;
use stdClass;

/**
 * Test helpers for Invitation mocks and stubs.
 */
trait InteractsWithInvitations
{
    /**
     * Create a mock Invitation for verifying method calls.
     *
     * Use when you need expects() assertions.
     *
     * @param array{
     *     id?: int,
     *     team_id?: int,
     *     invitee_id?: int,
     *     inviter_id?: int,
     *     team_name?: string,
     *     type?: InvitationType,
     *     status?: InvitationStatus,
     * } $attributes
     */
    protected function createInvitationMock(array $attributes = []): Invitation&MockObject
    {
        $attrs = array_merge([
            'id' => 1,
            'team_id' => 1,
            'invitee_id' => 2,
            'inviter_id' => 3,
            'team_name' => 'Test Team',
            'type' => InvitationType::Invitation,
            'status' => InvitationStatus::Pending,
        ], $attributes);

        $team = new stdClass();
        $team->name = $attrs['team_name'];

        $invitation = $this->createMock(Invitation::class);

        $invitation->method('__get')
            ->willReturnCallback(fn (string $prop) => match ($prop) {
                'id' => $attrs['id'],
                'team_id' => $attrs['team_id'],
                'invitee_id' => $attrs['invitee_id'],
                'inviter_id' => $attrs['inviter_id'],
                'team' => $team,
                'type' => $attrs['type'],
                'status' => $attrs['status'],
                default => null,
            });

        $invitation->method('fresh')->willReturn($invitation);

        return $invitation;
    }

    /**
     * Create a stub Invitation for return values only.
     *
     * Use when you don't need expects() assertions (faster).
     *
     * @param array{
     *     id?: int,
     *     team_id?: int,
     *     invitee_id?: int,
     *     inviter_id?: int,
     *     team_name?: string,
     *     fresh_result?: Invitation|null,
     * } $attributes
     */
    protected function createInvitationStub(array $attributes = []): Invitation&Stub
    {
        $attrs = array_merge([
            'id' => 1,
            'team_id' => 1,
            'invitee_id' => 2,
            'inviter_id' => 3,
            'team_name' => 'Test Team',
            'fresh_result' => null,
        ], $attributes);

        $team = new stdClass();
        $team->name = $attrs['team_name'];

        $invitation = $this->createStub(Invitation::class);

        $invitation->method('__get')
            ->willReturnCallback(fn (string $prop) => match ($prop) {
                'id' => $attrs['id'],
                'team_id' => $attrs['team_id'],
                'invitee_id' => $attrs['invitee_id'],
                'inviter_id' => $attrs['inviter_id'],
                'team' => $team,
                default => null,
            });

        $invitation->method('fresh')
            ->willReturn($attrs['fresh_result'] ?? $invitation);

        return $invitation;
    }

    /**
     * Create a pending invitation stub (convenience).
     */
    protected function createPendingInvitationStub(): Invitation&Stub
    {
        $stub = $this->createInvitationStub();
        $stub->method('isPending')->willReturn(true);

        return $stub;
    }

    /**
     * Create an accepted invitation stub (convenience).
     */
    protected function createAcceptedInvitationStub(): Invitation&Stub
    {
        $stub = $this->createInvitationStub(['status' => InvitationStatus::Accepted]);
        $stub->method('isPending')->willReturn(false);

        return $stub;
    }
}
```

## Using Traits

```php
<?php

declare(strict_types=1);

namespace Tests\Unit\Actions;

use App\Actions\AcceptInvitationAction;
use Tests\Concerns\InteractsWithInvitations;
use PHPUnit\Framework\Attributes\CoversClass;
use Tests\TestCase;

#[CoversClass(AcceptInvitationAction::class)]
class AcceptInvitationActionTest extends TestCase
{
    use InteractsWithInvitations;

    public function testDelegatesStateTransitionToModel(): void
    {
        // Use trait method with defaults
        $invitation = $this->createInvitationMock();

        $invitation->expects($this->once())->method('accept');

        // ... test
    }

    public function testWithCustomAttributes(): void
    {
        // Override specific attributes
        $invitation = $this->createInvitationMock([
            'id' => 99,
            'team_name' => 'Custom Team',
        ]);

        // ... test
    }
}
```

## Design Principles

### 1. Configurable Through Parameters

```php
// ✅ GOOD - accepts attributes array
protected function createInvitationMock(array $attributes = []): MockObject
{
    $attrs = array_merge($defaults, $attributes);
}

// ❌ BAD - hardcoded, not reusable
protected function createInvitationMock(): MockObject
{
    // Always id=1, can't customize
}
```

### 2. Sensible Defaults

Work with zero configuration for common cases:

```php
// Works out of the box
$invitation = $this->createInvitationMock();

// Customizable when needed
$invitation = $this->createInvitationMock(['id' => 99]);
```

### 3. Separate Mock vs Stub

```php
// Mock - for verification (expects)
protected function createInvitationMock(): MockObject;

// Stub - for return values only (faster)
protected function createInvitationStub(): Stub;
```

### 4. Convenience Methods

Add shortcuts for common configurations:

```php
// Generic with full control
protected function createInvitationStub(array $attributes = []): Stub;

// Convenience shortcuts
protected function createPendingInvitationStub(): Stub;
protected function createAcceptedInvitationStub(): Stub;
protected function createDeniedInvitationStub(): Stub;
```

### 5. Type Safety

Use intersection types and PHPDoc array shapes:

```php
/**
 * @param array{id?: int, status?: InvitationStatus} $attributes
 */
protected function createInvitationMock(array $attributes = []): Invitation&MockObject
```

## When to Extract

**Before (duplication):**
```php
// AcceptInvitationActionTest.php
private function createInvitationMock() { /* ... */ }

// DenyInvitationActionTest.php
private function createInvitationMock() { /* ... */ }

// CancelInvitationActionTest.php
private function createInvitationMock() { /* ... */ }
```

**After (trait):**
```php
// Concerns/InteractsWithInvitations.php
trait InteractsWithInvitations
{
    protected function createInvitationMock(array $attributes = []) { /* ... */ }
}

// All tests just use the trait
use InteractsWithInvitations;
```

## Key Points

- **Naming:** `InteractsWith{Domain}` (Laravel convention)
- **Location:** `tests/Concerns/` directory
- **Threshold:** Create when used in 3+ test classes
- **Configurability:** Accept `$attributes` array with defaults
- **Mock vs Stub:** Provide both when tests need verification vs return values
- **Type safety:** Intersection types (`MockObject&Model`) + PHPDoc shapes
- **Convenience:** Add shortcuts for common states
