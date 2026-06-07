---
description: Generate Laravel queued Jobs (background work, async processing, deferred tasks). Use whenever the user mentions a queued job, background task, async operation, batch processing, dispatching work to a queue, or anything that should run outside the request cycle in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/job** skill. Parse the user's background-work request and delegate to the `job` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Job class name** (`SendOrderReceiptJob`, `RebuildSearchIndexJob`)
- **What it does** — the Action it should delegate to
- **Inputs** — scalar IDs only (never models)
- **Dispatch site** — where it's dispatched from (an Action, a command, etc.)
- **Retry/timeout** if the user implies anything beyond defaults

⚠️ If the user describes "react to event X by doing Y in the background", that's a queued LISTENER, not a job — suggest `/listener` (or `/event` for both).

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Job vs queued listener unclear → if no event is involved, it's a job
- The Action it delegates to doesn't exist → offer to run `/action` first
- Retry/timeout unstated → default `tries=3`, default timeout; confirm only if the request implies otherwise

## Delegate

Use the Task tool with `subagent_type: "job"`, passing the parsed details.

## Synthesize

Report at the feature level: job path, constructor inputs, the Action it delegates to, retry config, and dispatch site. Example:

> Created `app/Jobs/SendOrderReceiptJob.php` — constructor `int $orderId`, `handle()` injects `SendOrderReceipt`, `#[Tries(3)]`. Idempotent (skips if the receipt was already sent). Dispatch via `SendOrderReceiptJob::dispatch($order->id)` from your action layer.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't route a "react to an event" request here — that's `/listener`
