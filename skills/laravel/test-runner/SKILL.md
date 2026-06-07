---
description: Run a project's Laravel tests (resolve the command, run, report failures). Use when the user wants to run tests, re-run a failing test, or verify a change — not to write new tests (use /feature-test or /unit-test for that).
argument-hint: [optional — test file, --filter=..., or scope]
---

You're the **/test-runner** skill. Translate the user's request into an enriched delegation to the `test-runner` agent. This runs existing tests; it does not write them.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Scope**: whole suite | a file (`tests/Feature/OrderTest.php`) | a `--filter` name | a changed area
- **Mode**: full run | fast iterate (`--stop-on-failure`) | parallel

## Step 2: Resolve Ambiguity

- No scope given → run the suite, but if a specific feature was just worked on, offer to scope to it
- "Why is X failing?" → scope to X with `--filter` and report the failing assertion

## Step 3: Build Context Blob

```
Context for test-runner agent:
- Scope: suite | tests/Feature/OrderTest.php | --filter=OrderTest
- Mode: full | --stop-on-failure | --parallel
```

## Step 4: Delegate

Task tool, `subagent_type: "test-runner"`, pass the blob.

## Step 5: Synthesize

Report pass/fail, counts, and for failures the test + assertion. Don't dump the full log.

## When to Ask vs Assume

- The command → defer to the agent (it follows the running-tests pattern; default `php artisan test`)
- Writing tests → not this skill; redirect to `/feature-test` or `/unit-test`
- Full quality gate (lint + static analysis + tests) → that's a separate concern, not this skill
