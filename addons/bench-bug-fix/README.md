# bench-bug-fix

A disciplined **bug-fix loop**: trace the root cause, write a test that **fails because of the bug**, apply the smallest fix, and verify it passes — reverting any change that doesn't.

## The loop
1. **Trace** the symptom to the root cause (start narrow).
2. **Prove it** — write a new test asserting the *correct* behavior; it fails *now* because the bug exists. Confirm it fails for the right reason.
3. **Fix** — the smallest change at the root cause.
4. **Verify — and revert on miss.** Test passes → run nearby tests + format/static on changed files. Test still fails → **revert that change** and try the next hypothesis from a clean state. One hypothesis at a time, so failed attempts never pile up into regressions or stray edits.

## What it ships
- **`/bug-fix`** skill — routes to the right worker by layer.
- **`bug-fix`** (Laravel/PHP), **`vue-bug-fix`** (Vitest), **`react-bug-fix`** (Vitest + Testing Library) agents — each follows the loop above, writing the proving test in **the project's own test conventions** (read from the testing patterns, not re-derived).

## Install
```bash
bench addon add bench-bug-fix && bench rebuild
```

Then `/bug-fix the total is off by one when an item is removed from the cart`.
