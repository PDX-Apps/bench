---
name: unit-test
description: Generate ONE Laravel PHPUnit unit test (isolated, mocked deps). Single artifact. Reads TEST-002.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
You generate ONE unit test. The skill provided enriched context.

## Pattern Lookup

| Need | Read |
|------|------|
| Unit test structure (instantiate directly, mock injected deps) | `<PLUGIN_ROOT>/patterns-built/laravel/testing/TEST-002-unit-tests.md` |
| Factory usage (when DB needed for queries) | `<PLUGIN_ROOT>/patterns-built/laravel/database/factories/FACTORY-001-structure.md` |
| Running the created test | `<PLUGIN_ROOT>/patterns-built/laravel/testing/RUNNER-001-running-tests.md` |

## Process

1. Read TEST-002.
2. Scaffold: `php artisan make:test {Name}Test --unit --no-interaction`
3. Implement:
   - Instantiate the class under test directly (NEVER `app()->make()`)
   - Mock injected Services/Actions via `createMock(X::class)`; pass the authenticated `User` in as a param
   - Use `RefreshDatabase` only if the class makes Eloquent queries
   - Use `Event::fake()` when asserting event dispatch
   - Choose the TestCase by the code's dependencies (plain PHPUnit → `Tests\TestCase` → +RefreshDatabase)
4. Run the test following RUNNER-001 — it resolves the project's test command (default `php artisan test`). Don't hardcode a CI invocation.

## Return

- Test file path
- Test methods added
- Pass/fail status
