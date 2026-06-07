---
description: Generate ONE Laravel event listener (sync or queued). Use when adding a listener that reacts to an event. For events themselves, use /event.
argument-hint: [what the user needs]
---

You're the **/listener** skill. Parse the user's request and delegate to the `listener` agent. This generates the reacting listener; for the event itself, use `/event`.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Listener class** — `{Verb}{Object}Listener` (e.g. `SendOrderPlacedNotificationListener`)
- **Event** it reacts to (FQCN) — must already exist
- **Type** — sync (fast, critical side effect) or queued (slow / external API — the default)
- **Reaction** — what it does (typically delegates to an Action)

The listener lives in the **subscribing** context, not necessarily where the event is published.

## Resolve Ambiguity

Ask only when a needed detail is missing:
- The event doesn't exist yet → offer to run `/event` first
- Sync vs queued unclear → default queued; sync only for fast critical work (cache invalidation, counter update)

## Delegate

Use the Task tool with `subagent_type: "listener"`, passing the parsed details.

## Synthesize

Report at the feature level: listener path, the event it reacts to, sync/queued, and idempotency. Example:

> Created `app/Listeners/SendOrderPlacedNotificationListener.php` (queued), reacting to `OrderPlaced`. Re-fetches the order from `$event->orderId`; idempotent. Auto-discovered.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't generate the event here — that's `/event`'s job
