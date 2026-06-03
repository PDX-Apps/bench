---
description: Generate a Laravel PHPUnit UNIT test (isolated logic, mocked dependencies). Use for testing Actions, Services, model methods in isolation. For HTTP/endpoint tests, use /feature-test.
argument-hint: [what the user needs]
---

You're the **/unit-test** skill. Translate the user's unit test request into an enriched delegation to the `unit-test` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Bill, Audit, etc.)
- **Test class** — `{Class}Test`
- **Class under test**: Action / Service / Model domain method
- **Dependencies to mock**: other Actions, Services, AuthService
- **Cases**: golden, edge cases, error paths

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/tests/Unit/ 2>/dev/null
# Confirm class under test exists
ls Modules/{Module}/app/Actions/ Modules/{Module}/app/Services/ Modules/{Module}/app/Models/ 2>/dev/null
ls Modules/{Module}/database/factories/ 2>/dev/null  # for unmockable DB queries
```

## Step 3: Resolve Ambiguity

- Class missing → flag: "Test for `MarkBillPaidAction` — class doesn't exist. Generate `/action` first?"
- DB usage in unit test → assume yes when class makes Eloquent queries; use `RefreshDatabase`. Only mock-only when truly pure logic.

## Step 4: Build Context Blob

```
Context for unit-test agent:
- Module: {Module}
- Class: {Name}Test
- Path: Modules/{Module}/tests/Unit/{Name}Test.php
- Class under test: \Modules\Bill\Actions\MarkBillPaidAction
- Dependencies to mock: [AuthService, NotificationDispatcher]
- Real DB needed: yes (uses Eloquent) | no (pure logic)
- Available factories: [BillFactory, UserFactory]
- Cases: [
    test_marks_bill_as_paid_and_dispatches_event
    test_throws_when_bill_already_paid
    test_only_creator_can_mark_paid
  ]
- Existing siblings: [...]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:unit-test"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/tests/Unit/MarkBillPaidActionTest.php` with 3 unit tests. AuthService mocked via `createMock()`. Real DB via `RefreshDatabase`. `Event::fake()` for event dispatch assertions. CI passing."

## When to Ask vs Assume

- Instantiate directly (`new ActionClass($mockedDep)`) — NEVER `app->make()` → always
- Mock injected dependencies; real DB for queries → standard pattern
- `Event::fake()` for event assertions → always when action dispatches events
