---
description: Generate a Laravel Action class — a single-purpose business operation with one `execute()` method and side effects (persistence, event dispatch, notifications). Use whenever the user describes a business operation like "create X", "send Y", "process Z", "mark W". For utility/calculator/parser classes use /service instead.
argument-hint: [what the user needs]
---

You're the **/action** skill. Parse the user's request, ask one question if anything's ambiguous, delegate to the `action` agent, then synthesize its output.

The user's request: **$ARGUMENTS**

## Parse

Extract:
- **Class name** — `{Verb}{Noun}Action` (propose one if the user didn't name it)
- **Inputs** — scalar params or a DTO?
- **Side effects** — dispatches an event? sends a notification? calls another Action?
- **Needs current user?** — yes if the action touches user-owned data

## Resolve ambiguity

If the request describes a utility/calculator/parser (multiple methods, no orchestration side effects) → redirect to `/service`.

Otherwise: ask the user ONE question if anything's genuinely ambiguous. Don't ask three questions when one disambiguates the rest. For obvious cases, proceed.

## Delegate

Use the Task tool with `subagent_type: "action"`. Pass the **parsed args** (class name, inputs, side effects, needs-current-user flag) — NOT the raw `$ARGUMENTS`. The agent reads the pattern, scaffolds, and reports back.

## Synthesize

Re-frame the agent's output at the feature level for the user. Mention any follow-ups it flagged (missing event, missing model, suggested next skill).
