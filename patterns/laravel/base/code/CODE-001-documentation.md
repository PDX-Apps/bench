# CODE-001-documentation

## Pattern

Code documentation standards using doc blocks and comments.

## Doc Blocks (Required)

**All classes, methods, and functions must have doc blocks.**

```php
/**
 * Ensure max_members does not surpass a tier maximum.
 *
 * @throws MaxMembersExceededException
 */
public function ensureIsNotOverRoommateLimit(): void
{
    if ($this->max_members > $this->user->tier->max_members) {
        throw new MaxMembersExceededException();
    }
}
```

## What to Document

**DO document:**
- What the code does
- Exceptions thrown
- Edge cases or important behavior
- Parameters/return types ONLY when they add non-obvious context

**DON'T document:**
- Why rules exist (that's in RULE-* files)
- Spec references (that's in the spec)
- Obvious things ("Get user" for `getUser()`)
- Redundant @param/@return tags that just restate type hints

## Array Type Annotations

**All array properties must be typed with PHPStan/Psalm annotations.**

### Generic Arrays

```php
/**
 * User preferences configuration.
 *
 * @var array<string, mixed>
 */
public array $preferences;
```

### Known Structure (Array Shapes)

```php
/**
 * @var array{
 *     id: int,
 *     name: string,
 *     email: string|null
 * }
 */
public array $userData;

/**
 * Optional keys use "?" suffix.
 *
 * @var array{
 *     id: int,
 *     name: string,
 *     updated_at?: string
 * }
 */
public array $data;
```

### Sequential Arrays (Lists)

```php
/**
 * @var list<string>
 */
public array $tags;

/**
 * @var list<int>
 */
public array $ids;
```

### Nested Arrays

```php
/**
 * @var array<string, array<string, mixed>>
 */
public array $nestedConfig;

/**
 * @var list<array{id: int, name: string}>
 */
public array $items;
```

### Non-Empty Arrays

```php
/**
 * @var non-empty-array<string, mixed>
 */
public array $requiredData;
```

### Guidelines

- Use `array<string, mixed>` for generic associative arrays
- Use array shapes `array{key: type}` when structure is known
- Use `list<type>` for sequential arrays (0-indexed)
- Add descriptive comments explaining what the array contains
- Consider DTOs for complex nested structures

## Examples

### Good Documentation

```php
/**
 * Generate unique slug from name for the given user.
 * Appends number if the slug already exists (e.g., "budget-name" or "budget-name-2").
 */
protected function generateUniqueSlug(string $name, int $userId): string
{
    $slug = Str::slug($name);
    $originalSlug = $slug;
    $count = 1;

    while ($this->slugExists($slug, $userId)) {
        $slug = "{$originalSlug}-{$count}";
        $count++;
    }

    return $slug;
}

/**
 * Execute the action to create a household.
 */
public function execute(HouseholdData $data): Household
{
    // Implementation
}
```

**Why no @param/@return?** Type hints already document the types. Only add @param/@return when providing non-obvious context.

### Bad Documentation

```php
// To meet RULE-002 - unique slug per user
protected function generateUniqueSlug(string $name, int $userId): string  // ❌ No doc block
{
    // Generate slug to meet spec requirements  // ❌ References spec
    $slug = Str::slug($name);

    // Check if exists (RULE-002)  // ❌ References rule
    while ($this->slugExists($slug, $userId)) {
        $slug = "{$originalSlug}-{$count}";
        $count++;
    }

    return $slug;
}
```

## Inline Comments

**Use sparingly.** Only when code behavior is non-obvious.

```php
// Good - explains non-obvious behavior
if ($household->user_id === null) {
    // User was deleted (GDPR) - display as "Deleted User"
    return 'Deleted User';
}

// Bad - states the obvious
$slug = Str::slug($name);  // ❌ Convert name to slug
```

## Method Visibility

**Prefer `protected` over `private`:**
- Allows testing without reflection
- Enables extension and overriding
- Minimal downside in Laravel context
- Only use `private` for truly internal implementation details

## Key Points

- **Doc blocks are required** for all public/protected methods
- Use `protected` for helper methods (not `private`)
- Describe WHAT, not WHY (why is in specs/rules)
- No spec/rule references in code
- Omit redundant @param/@return tags when type hints are self-explanatory
- Only add @param/@return when providing non-obvious context
- Inline comments only for non-obvious behavior
- Focus on a developer understanding the code itself
