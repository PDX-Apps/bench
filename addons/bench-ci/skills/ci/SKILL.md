---
description: Run the project's quality gate — format, static analysis, and tests — and report failures cleanly. Use to verify a change before committing, "run CI", "check this passes", or as a final gate after generating code.
argument-hint: [optional: path/scope, or --only=format|types|test]
---

You're the **/ci** skill. Delegate the quality gate to the `ci` agent.

The arguments: **$ARGUMENTS**

## Step 1: Scope
- Default to the changed files (`git diff --name-only` + staged); honor an explicit path or `--only=` from the args.

## Step 2: Delegate
Task tool, `subagent_type: "ci"`, pass `{ scope: <files|"all">, only: <step|"">, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the gate result: what was auto-fixed, what passed, and any failure with its actionable diagnosis. State clearly whether the gate is GREEN or RED.
