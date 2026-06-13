---
description: Run the project's quality pipeline — the stages it declared in .bench/ci.yaml for a lifecycle trigger (format, tests, static analysis, code review, e2e, docs, whatever the project defined) — and report GREEN/RED cleanly. Use to verify a change before reporting it done, "run CI", "run the pipeline", or as a final gate after generating code.
argument-hint: "[trigger e.g. on_done | --only=<stage> | path/scope]"
---

You're the **/ci** skill. Delegate the quality pipeline to the `ci` agent. The stages are whatever the
project declared in `.bench/ci.yaml` — you don't define or assume them.

The arguments: **$ARGUMENTS**

## Step 1: Parse
- **trigger** — a bare word matching a trigger name (`on_done`, `before_start`, `before_commit`);
  default `on_done`.
- **`--only=<name>`** — limit the run to one declared stage (by its `name`).
- **scope** — default to the changed files (`git diff --name-only` + staged); honor an explicit path.

## Step 2: Delegate
Task tool, `subagent_type: "ci"`, pass `{ trigger: <name|"on_done">, only: <stage|"">, scope: <files|"all">, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the pipeline result: the trigger run, what was auto-fixed, what passed, and any failure with its
actionable diagnosis. State clearly whether the pipeline is GREEN or RED.
