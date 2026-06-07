---
description: Generate a PHP 8.1 backed enum for status/type/mode fields. Use whenever the user mentions an enum, status type, role enum, or wants type-safe alternatives to string constants in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/enum** skill. Parse the user's enum request and delegate to the `enum` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Enum class name** — TitleCase + descriptive (`OrderStatus`, `SubscriptionInterval`, `NotificationChannel`)
- **Backing type** — string (default) or int
- **Cases** — TitleCase case names with values
- **Domain methods** suggested by the request (`label()`, `color()`, `canTransitionTo()`)
- **Model that uses it** — so the agent can register it in `casts()`

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Cases not given → ask once, with examples
- Domain methods unclear → suggest `label()` (UI display) / `color()` (status badges); confirm if needed

## Delegate

Use the Task tool with `subagent_type: "enum"`, passing the parsed details.

## Synthesize

Report at the feature level: enum path, backing type, cases, and whether a model `casts()` was wired. Example:

> Created `app/Enums/OrderStatus.php` (string-backed: Pending, Paid, Shipped, Cancelled) with `label()` + `color()`. Registered in the `Order` model `casts()` as `'status' => OrderStatus::class`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
