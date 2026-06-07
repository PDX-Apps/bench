---
description: Generate a Laravel model factory (database/factories/{Model}Factory.php). Use when the user wants ONLY a factory.
argument-hint: [what the user needs]
---

You're the **/factory** skill. Parse the user's request and delegate to the `factory` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Model** the factory is for (must exist)
- **State methods** — field states (`shipped()`, `cancelled()`) and relationship states (`forCustomer($c)`)
- **Default attributes** — Faker for realistic data; `PublicId::generate()` for public-id columns

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Model doesn't exist yet → offer to run `/model` first
- State methods unclear → ask for the common variations (e.g. "`shipped()`, `cancelled()`, `forCustomer($c)`?")

## Delegate

Use the Task tool with `subagent_type: "factory"`, passing the parsed details.

## Synthesize

Report at the feature level: factory path, the `@extends` PHPDoc, and state methods. Example:

> Created `database/factories/OrderFactory.php` with `@extends Factory<Order>` and state methods `shipped`, `cancelled`, `forCustomer`. Usable: `Order::factory()->shipped()->create()`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
