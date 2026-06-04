---
description: Generate a Laravel PHPUnit FEATURE test (HTTP/end-to-end). Use for testing endpoints, controllers, full request→response flows. For isolated logic tests, use /unit-test.
argument-hint: [what the user needs]
---

You're the **/feature-test** skill. Translate the user's feature test request into an enriched delegation to the `feature-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Household, etc.)
- **Test class** — `{ActionDescription}Test` (e.g., `MarkBillPaidTest`, `CreatePersonalBillTest`)
- **Endpoint under test** + HTTP method
- **Cases**: golden path, unauthorized (401), forbidden (403), not found (404), validation failure (422), conflict (409)
- **Regression for bug** if applicable

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/tests/Feature/ 2>/dev/null
ls Modules/{Module}/tests/Support/ 2>/dev/null  # test traits
ls Modules/{Module}/database/factories/ 2>/dev/null  # factories available
```

## Step 3: Resolve Ambiguity

- Endpoint not yet existing → flag: "Test for `POST /bills/{id}/mark-paid` — no controller. Generate `/controller` first?"
- Cases not specified → suggest standard set (golden + 401 + 403 + 404 + 422 if FormRequest exists)

## Step 4: Build Context Blob

```
Context for feature-test agent:
- Module: {Module}
- Class: {Name}Test
- Path: Modules/{Module}/tests/Feature/{Name}Test.php
- Endpoint: POST /bills/{id}/mark-paid → MarkBillPaidController
- #[CoversClass]: \Modules\Bill\Http\Controllers\MarkBillPaidController
- #[Group]: 'bill'
- Available factories: [BillFactory (paid, overdue, forHousehold), UserFactory, HouseholdFactory (withMember)]
- Test traits: [InteractsWithBills if exists]
- Cases: [
    test_member_can_mark_bill_paid (golden, 200)
    test_non_member_gets_403
    test_unauthenticated_gets_401
    test_already_paid_returns_409
    test_invalid_bill_id_returns_404
  ]
- Existing siblings: [ShowBillTest.php, ...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:feature-test"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/tests/Feature/MarkBillPaidTest.php` with 5 test methods. `RefreshDatabase`, `#[CoversClass]`, `#[Group('bill')]`. CI passing for module Bill (`composer ci -- --module=Bill --only=test --fail-on-error`)."

## When to Ask vs Assume

- PHPUnit (`--phpunit`) → always (NEVER Pest)
- `RefreshDatabase` → always
- Use factory states → discover from inspection
- `data-testid` style for test method names → e.g., `test_member_can_X`
