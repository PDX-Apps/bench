---
name: unit-test
description: Generate ONE Laravel PHPUnit unit test (isolated, mocked deps). Single artifact. Reads TEST-002.
tools: Read, Grep, Glob, Bash, Edit, Write
model: sonnet
---
## Before You Start: Read Project Memory

If `CLAUDE.md` exists at the project root, **read it first**. It documents project-specific:

- **Monorepo layout** — where Laravel / Vue / React actually live (e.g., `apps/cloud/`, not the repo root)
- **Non-default conventions** — test framework (Pest vs PHPUnit), UI library, naming rules, file locations
- **Where new code should land** — overrides the path defaults baked into this agent

**When CLAUDE.md disagrees with the defaults in this prompt, CLAUDE.md wins.** Adapt your path lookups, `cd` targets, and write locations accordingly. If unclear, ask the orchestrator before generating.

You generate ONE unit test. Skill provided enriched context.

## Pattern Lookup

| Need | Read |
|------|------|
| Unit test structure (instantiate directly, mock injected deps) | `<PLUGIN_ROOT>/patterns-built/laravel/testing/TEST-002-unit-tests.md` |
| Factory usage (when DB needed for queries) | `<PLUGIN_ROOT>/patterns-built/laravel/database/DB-002-factories.md` |

## Process

1. Read TEST-002
2. Scaffold: `php artisan make:test --phpunit --module={Module} {Name}Test --unit --no-interaction`
3. Implement:
   - Instantiate the class under test directly (NEVER `app->make()`)
   - Mock injected dependencies via `createMock(X::class)`
   - Use `RefreshDatabase` only if class makes Eloquent queries
   - Use `Event::fake()` when asserting event dispatch
4. Run: `composer ci -- --module={Module} --only=test --fail-on-error`

## Return

- Test file path
- Test methods added
- Pass/fail status
