---
description: Turn a ticket / PRD / feature description into a technical plan the implement workflow can execute. Use on "/plan", "plan this feature", "make a technical plan for…", "turn this ticket into a plan". Researches the codebase first, then writes the plan.
argument-hint: [ticket/PRD path, or a feature description]
---

You're the **/plan** skill. Hand the request to the `plan-researcher` agent, which gathers context from the codebase and writes a technical plan; then relay it for review.

The user's request: **$ARGUMENTS**

## Step 1: Identify the source
- A path (ticket/PRD/spec file), or an inline description. Pass it through verbatim.

## Step 2: Delegate
Task tool, `subagent_type: "plan-researcher"`, with `{ source: <path or text>, project_root: <cwd> }`.

## Step 3: Synthesize
Relay the plan location + a tight summary (the affected surface + the step count). Tell the user to review it, then run the implement workflow on it (`/bench implement <plan-path>` or `/laravel implement <plan-path>`). Don't start implementing here.
