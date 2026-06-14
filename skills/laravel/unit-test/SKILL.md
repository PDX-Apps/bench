---
description: Generate a Laravel PHPUnit UNIT test (isolated logic, mocked dependencies). Use for testing Actions, Services, model domain methods in isolation. For HTTP/endpoint tests, use /feature-test; to audit a whole feature's tests against the strategy and fill the gaps, use /test-audit.
argument-hint: [what the user needs]
---

You're the **/unit-test** skill. Translate the user's unit test request into an enriched delegation to the `unit-test` agent. This generates the test and runs it via the project's configured test command; to customize how the AI runs tests, use `/test-runner`.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Test class** — `{Class}Test`
- **Class under test**: Action / Service / model domain method
- **Dependencies to mock**: the Services / other Actions it injects
- **Cases**: golden path, edge cases, error paths

## Step 2: Resolve Ambiguity

- Class under test missing → flag: "Test for `CreateOrderAction` — the class doesn't exist. Generate `/action` first?"
- Real DB needed → yes when the class runs Eloquent queries (`RefreshDatabase`); otherwise pure-logic with mocks only

## Step 3: Build Context Blob

```
Context for unit-test agent:
- Class: {Name}Test
- Class under test: App\Actions\CreateOrderAction
- Dependencies to mock: [PricingCalculator]
- Authenticated user: passed into execute() as a param (not mocked)
- Real DB needed: yes (uses Eloquent) | no (pure logic)
- Cases: [
    test_creates_order_and_charges_payment
    test_throws_when_subtotal_invalid
  ]
```

## Step 4: Delegate

Task tool, `subagent_type: "unit-test"`, pass the blob.

## Step 5: Synthesize

Report the test path, the cases added, mocking approach, and pass/fail.

## When to Ask vs Assume

- Instantiate directly (`new ActionClass($mock)`) — NEVER `app()->make()` → always
- Mock injected Services/Actions; pass the `User` in as a param; real DB only for unmockable queries
- Don't dictate the test framework or runner — that's `/test-runner`'s job, not this skill's call
