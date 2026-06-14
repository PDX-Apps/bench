---
description: Generate a Laravel feature test (HTTP/end-to-end). Use for testing endpoints, controllers, full request→response flows. For isolated logic tests, use /unit-test; to audit a whole feature's tests against the strategy and fill the gaps, use /test-audit.
argument-hint: [what the user needs]
---

You're the **/feature-test** skill. Parse the user's request and delegate to the `feature-test` agent. This generates the test and runs it via the project's configured test command; to customize how the AI runs tests, use `/test-runner`.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Test class** — `{ActionDescription}Test` (e.g. `MarkOrderShippedTest`, `CreateOrderTest`)
- **Endpoint under test** + HTTP method
- **Cases** — golden path plus the relevant failures: 401 unauthenticated, 403 forbidden, 404 not found, 422 validation, 409 conflict
- **Regression** for a specific bug, if applicable

## Resolve Ambiguity

Ask only when a needed detail is missing:
- The endpoint doesn't exist yet → offer to run `/controller` first
- Cases unspecified → suggest the standard set (golden + 401 + 403 + 404 + 422 when a FormRequest exists)

## Delegate

Use the Task tool with `subagent_type: "feature-test"`, passing the parsed details.

## Synthesize

Report at the feature level: test path and the cases covered. Example:

> Created `tests/Feature/MarkOrderShippedTest.php` with 5 cases: golden (200), 403 non-owner, 401 unauthenticated, 409 already-shipped, 404 unknown order. `RefreshDatabase`, `#[CoversClass]`, `#[Group('order')]`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't dictate the test framework or runner — that's `/test-runner`'s job, not this skill's call
