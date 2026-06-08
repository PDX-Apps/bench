# bench-ci

A **quality gate** that runs the project's *own* formatter, static analysis, and tests — and reports failures cleanly.

## What it ships
- **`/ci`** skill → the **`ci`** agent: detects the project's tools (Pint/Prettier/ESLint, PHPStan/Larastan/tsc, Pest/PHPUnit/Vitest), auto-fixes formatting, runs format → static → tests (stopping at the first failure), and reports an actionable diagnosis. The `ci` agent is delegatable, so other addons (e.g. `bench-quality`) can run the gate without duplicating it.

No bespoke CI assumptions — it discovers whatever the project has.

## Install
```bash
bench addon add /path/to/bench/addons/laravel-ci && bench rebuild
```
