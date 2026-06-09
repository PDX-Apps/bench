---
description: Run the project's quality gate — the steps it declared in .bench/ci.yaml (format, static analysis, tests, whatever the project defined) — and report failures cleanly. Use to verify a change before committing, "run CI", "check this passes", or as a final gate after generating code.
argument-hint: [optional: path/scope, or --only=<step name>]
---

You're the **/ci** skill. Delegate the quality gate to the `ci` agent. The gate's steps are whatever the project declared in `.bench/ci.yaml` — you don't define or assume them.

The arguments: **$ARGUMENTS**

## Step 1: Scope
- Default to the changed files (`git diff --name-only` + staged); honor an explicit path. `--only=<name>` limits the run to one declared step (by its `name` in `.bench/ci.yaml`).

## Step 2: Delegate
Task tool, `subagent_type: "ci"`, pass `{ scope: <files|"all">, only: <step name|"">, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the gate result: what was auto-fixed, what passed, and any failure with its actionable diagnosis. State clearly whether the gate is GREEN or RED.
