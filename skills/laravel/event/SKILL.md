---
description: Generate a Laravel domain event class. Use whenever the user describes something important happening in the domain that should be announced for other parts of the system to react to — "when X happens" / "emit an event when…" — or mentions events, broadcasting, or pub/sub in a Laravel project. For the code that reacts to an event, use /listener.
argument-hint: [what the user needs]
---

You're the **/event** skill. Parse the user's request and delegate to the `event` agent. This generates ONE event class; for the code that reacts to it, use `/listener`.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Event name** — past tense for completed actions (`OrderPlaced`, `SubscriptionCancelled`), "Will" for scheduled, "Detected" for observed state
- **Payload** — which IDs to carry (default), or a model/snapshot when point-in-time data is wanted
- **Dispatch site** — where the event fires from (typically an Action)

⚠️ If the user says "send X in the background" with no event involved, that's a JOB — suggest `/job`. If they describe the *reaction* to an event (notify, log, sync), that's a listener — suggest `/listener`.

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Event vs job unclear → "trigger X automatically when Y happens" is an event; "send Y in the background" is a job
- Payload unclear → default to IDs; confirm if a point-in-time snapshot is wanted

## Delegate

Use the Task tool with `subagent_type: "event"`, passing the parsed details.

## Synthesize

Report at the feature level: event path, payload, and where it dispatches from. Point to `/listener` for the reaction. Example:

> Created `app/Events/OrderShipped.php` (payload `int $orderId`), dispatched from `ShipOrderAction::execute()`. Use `/listener` to add the code that reacts to it.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't generate the reacting listener here — that's `/listener`'s job
