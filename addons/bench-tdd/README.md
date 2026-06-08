# bench-tdd

A test-driven **bug-fix loop**: reproduce the bug with a failing test, make the smallest fix, verify it passes and nothing else broke.

## What it ships

- **`/bug-fix`** skill — routes to the right worker by layer.
- **`bug-fix`** (Laravel/PHP), **`vue-bug-fix`** (Vitest), **`react-bug-fix`** (Vitest + Testing Library) agents — each reproduces with a failing test, fixes minimally, and verifies using **the project's own test runner** (detected, not assumed).

## Install

```bash
bench addon add /path/to/bench/addons/tdd
bench rebuild
```

Then `/bug-fix the total is off by one when an item is removed from the cart`.
