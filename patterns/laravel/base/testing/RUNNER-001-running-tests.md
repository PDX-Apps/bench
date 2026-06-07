# RUNNER-001-running-tests

## Pattern

How to **run** tests — distinct from how to write them. This is the single place that resolves
the test command, so test-authoring agents (feature tests, unit tests) don't hardcode one. The
default is framework-native; real projects often wrap it, and that wrapper is an override of
this pattern.

## Default Command

```bash
php artisan test
```

`php artisan test` runs the whole suite and works the same whether the project uses **PHPUnit**
or **Pest** — both run through it. Use it unless the project defines its own command (below).

## Scoping a Run

Run the smallest relevant slice for fast feedback:

```bash
# A single test file
php artisan test tests/Feature/OrderTest.php

# By name (class or method substring)
php artisan test --filter=OrderTest
php artisan test --filter='it creates an order'

# Stop at the first failure while iterating
php artisan test --stop-on-failure

# Parallelize a large suite
php artisan test --parallel
```

After creating or changing a test, run **that test** (file or `--filter`) first; run the wider
suite once it passes.

## Framework: Pest vs PHPUnit

The **run** command is identical for both. The difference is only in how tests are *authored*
(that's the test-authoring patterns' concern, not this one). Detect which a project uses:

- **Pest** if `pestphp/pest` is in `composer.json` or a `tests/Pest.php` exists.
- **PHPUnit** otherwise.

Don't impose a framework here — match what the project already uses.

## Key Points

- Default to `php artisan test` — works for both PHPUnit and Pest
- Scope with a file path or `--filter`; `--stop-on-failure` while iterating; `--parallel` for large suites
- Don't dictate the framework — detect and match the project's
- Running tests is separate from the full quality gate (lint + static analysis + tests); this pattern covers only running tests
