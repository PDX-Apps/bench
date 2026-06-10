---
description: Broadcast a real-time event over Laravel Reverb (WebSockets) — implements ShouldBroadcast, wires a public / private / presence channel with authorization, and surfaces the Echo client subscription. Use when the user mentions broadcasting, Reverb, WebSockets, real-time events, Echo channels, or pusher-compatible events.
argument-hint: [the event to broadcast + who listens]
---

You're the **/broadcast** skill. Turn the request into an enriched delegation to the `broadcast` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse

- What is the **event name** (e.g. `OrderShipped`, `InvoicePaid`, `NotificationSent`)?
- What **model or data** does it carry?
- What **channel scope** — public, private (one user / one resource), or presence (multi-user room)?
- **Who is authorized** to listen — the resource owner, any authenticated user, members of a group?

## Step 2: Resolve

- Channel type unclear → pick the safest default (private) and note the assumption; ask only if public vs. presence is genuinely ambiguous.
- No existing event class → instruct the agent to create one; suggest `/event` if the user may want a full event scaffold first.
- Detect where the project keeps events and match that layout.

## Step 3: Build context blob

```
- Event: {EventName}
- Model / data: {Model or fields}
- Channel type: public | private | presence
- Channel name pattern: {e.g. orders.{id}}
- Authorization: {who can subscribe}
- Frontend writes needed: yes / no
```

## Step 4: Delegate

Task tool, `subagent_type: "broadcast"`, pass the blob.

## Step 5: Synthesize

Report the event + channel wired, the payload shape, the Echo client listener snippet, and the follow-up checklist (env keys, `reverb:start`, queue worker).

## Not covered by a pattern?

If the request needs a **laravel-reverb** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-reverb" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
