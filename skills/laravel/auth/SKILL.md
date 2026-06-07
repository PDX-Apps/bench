---
description: Configure Laravel framework-level auth — install/configure Sanctum, Fortify, Breeze, web/session auth wiring, guard configuration. Rare. Most authorization work is policies (use /policy instead).
argument-hint: [what the user needs]
---

You're the **/auth** skill. Parse the user's request, ask one question if anything's ambiguous, delegate to the `auth` agent, then synthesize its output.

For authorization (controllers/routes "can a user do X?") → redirect to `/policy`.

The user's request: **$ARGUMENTS**

## Parse

Extract the work type:
- `sanctum` — install/configure Sanctum for API tokens
- `web` — session-based web auth (Laravel default)
- `fortify` — install Laravel Fortify (headless auth)
- `breeze` — install Laravel Breeze (auth scaffolding)
- `guard` — custom guard configuration

Plus scope: app-wide or a specific area of the app.

## Resolve ambiguity

If the user asks about authorization for a specific controller/route → redirect to `/policy`.

If sanctum vs passport unclear → default to sanctum (modern Laravel default).

Otherwise: ask the user ONE question if anything's genuinely ambiguous. For obvious cases, proceed.

## Delegate

Use the Task tool with `subagent_type: "auth"`. Pass the parsed args (work type + scope) — NOT raw `$ARGUMENTS`. The agent reads the pattern, edits the relevant config files, and reports back.

## Synthesize

Re-frame the agent's output at the feature level for the user. Mention any follow-ups it flagged (composer install needed, config publish needed, restart Octane, etc.).
