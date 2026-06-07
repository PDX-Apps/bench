---
description: Generate Laravel custom Eloquent attribute casts. Use whenever the user mentions a custom cast, value object → DB column transformation (like Money, Address, Settings), JSON column casting, or needs typed access to a complex column attribute in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/cast** skill. Parse the user's request, ask one question if anything's ambiguous, delegate to the `cast` agent, then synthesize its output.

The user's request: **$ARGUMENTS**

## Parse

Extract:
- **Cast name** — `{Type}Cast` (e.g., `MoneyCast`, `AddressCast`)
- **Value type being cast** — what PHP type the cast produces (a value object class, a Data Object, an enum, etc.)
- **Single-column vs multi-column** — does it back ONE DB column (e.g., JSON settings) or MULTIPLE (e.g., Money = `amount` + `currency`)?
- **Target model(s)** — if the user mentioned which models will use the cast

## Resolve ambiguity

For obvious cases (`Money` cast → multi-column; `JSON settings` → single-column), proceed without asking.

If single-vs-multi-column is unclear, ask ONE question with the two options.

If the value object class doesn't yet exist, flag for the user — "the cast references `{Type}` which doesn't exist; should I scaffold that first or generate against a not-yet-existing class?"

## Delegate

Use the Task tool with `subagent_type: "cast"`. Pass the parsed args (cast name, value type, single/multi-column, target models) — NOT raw `$ARGUMENTS`. The agent reads the pattern, scaffolds the cast class, and reports back.

## Synthesize

Re-frame the agent's output at the feature level for the user. Mention follow-ups (need a migration to add the columns? need to update existing model `casts()` method?).
