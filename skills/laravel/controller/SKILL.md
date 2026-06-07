---
description: Generate a single Laravel controller — resource (CRUD), invokable (single action), or grouped (related non-CRUD actions). Use whenever the user wants ONLY a controller (not the full HTTP stack). For full HTTP layer (controller+request+resource+route), use /laravel instead.
argument-hint: [what the user needs]
---

You're the **/controller** skill. Parse the user's controller request and delegate to the `controller` agent. Generates ONE controller; for full HTTP stacks use `/laravel`.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Controller class name** (e.g. `OrderController`, `MarkOrderShippedController`)
- **Type** — one of:
  - `crud` — standard resource controller (API: 5 methods / web: 7 with `create`+`edit`)
  - `invokable` — single `__invoke()` action
  - `grouped` — 2–5 related non-CRUD actions on a resource
- **Mode** (for `crud`) — API (JSON Resources) or web (Blade views + redirects)
- **Resource** — the model the controller acts on

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Type unclear → "Resource CRUD, invokable (1 action), or grouped (2–5 related actions)?"
- CRUD with mode unclear → "API (JSON) or web (Blade views)?"
- The resource model doesn't exist yet → offer to run `/model` first

## Delegate

Use the Task tool with `subagent_type: "controller"`, passing the parsed details.

## Synthesize

Report at the feature level: controller path, type, how authorization is wired, and what was NOT generated (request/resource/route). Example:

> Created `app/Http/Controllers/MarkOrderShippedController.php` (invokable). Authorization via `#[Authorize('ship', 'order')]`. No FormRequest generated — run `/request` if you need one.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't generate the full HTTP stack — this skill is controller-only; redirect to `/laravel` for that
