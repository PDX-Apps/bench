---
description: Audit a feature's tests against Bench's test strategy (TEST-000) and generate the missing ones. Point it at a feature, a module, a directory, file paths, or "the changed files" — it works out which artifacts owe which test (Action→unit, Controller→feature, Event/Resource→asserted in the feature test, …) and fills the gaps. This is a BEHAVIORAL audit, NOT code-coverage measurement (no pcov/xdebug/line-%). For one test, use /unit-test or /feature-test.
argument-hint: [feature / module / paths / "the changed files"]
---

You're the **/test-audit** skill. Parse the **target** the user wants audited and delegate to the `test-audit` agent — it resolves the artifacts, applies the TEST-000 matrix, and generates the missing tests. You don't inspect the project yourself.

The user's request: **$ARGUMENTS**

## Parse

Extract the **target** to audit (pass it through; the agent resolves it to artifacts):
- a **feature** name ("the Device feature"),
- a **module** / directory (`Modules/Auth`, `app/Actions`),
- explicit **file paths**,
- or **"the changed files"** (the agent uses `git diff` to scope it).

## Delegate

Task tool, `subagent_type: "test-audit"`, pass `{ target, project_root: cwd }`.

## Synthesize

Report at the feature level: artifacts audited, tests **generated** (paths), what was **already covered**, and what is **covered inside the feature test** (Events/Resources). State the run result (green/red).

## Anti-Patterns

- Don't inspect the project or read files here — that's the agent's job.
- Don't **measure code coverage** — this is a behavioral audit against TEST-000, never pcov/xdebug/line-%.
- Don't dictate the test framework or runner — that's `/test-runner`'s call.
