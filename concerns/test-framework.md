---
concern: test-framework
title: Test framework
order: 10
detect: grep -q "pestphp/pest" composer.json 2>/dev/null && echo pest || echo phpunit
questions:
  - id: framework
    ask: "Which test runner does this project use?"
    options: [pest, phpunit]
    default: detect
  - id: feature_location
    ask: "Where do feature tests live?"
    default: tests/Feature
  - id: unit_location
    ask: "Where do unit tests live?"
    default: tests/Unit
  - id: syntax
    ask: "Pest projects: it() or test() style? (skip for PHPUnit)"
    options: [it, test]
    default: it
affects:
  - laravel/testing/RUNNER-001-running-tests.md
  - laravel/testing/TEST-001-feature-tests.md
  - laravel/testing/TEST-002-unit-tests.md
output: overrides
---

## Apply

Write `.bench/patterns/...` overrides (mode `append`) to **all three** affected patterns — this is the concern's whole point (don't update just one):

- **RUNNER-001-running-tests.md** — the project's run command:
  - Pest → `./vendor/bin/pest` (filter: `./vendor/bin/pest --filter={Name}`).
  - PHPUnit → `php artisan test` (filter: `php artisan test --filter={Name}`).
- **TEST-001-feature-tests.md** — feature tests live in `{feature_location}`; for Pest, use `{syntax}()` closures with `expect()`; for PHPUnit, `extends TestCase` with `test*` methods.
- **TEST-002-unit-tests.md** — unit tests live in `{unit_location}`; same syntax note as above.

Each override names the project's choice so generated tests + the runner all agree.
