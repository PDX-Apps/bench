---
description: Generate a Laravel domain Service class (calculator, parser, dispatcher, client). Different from Action — Services are stateless utilities with multiple methods and no required side effects. Use when the user describes a calculation, parser, formatter, or external client.
argument-hint: [what the user needs]
---

You're the **/service** skill. Translate the user's domain service request into an enriched delegation to the `service` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Class name** — descriptive of purpose, NO generic `Service` suffix (`PricingCalculator`, `NotificationDispatcher`, `StripeClient`, `CurrencyConverter`)
- **Methods** — multiple related methods OK
- **Dependencies** — constructor-injected collaborators
- **Domain boundary** — should stay within one domain

⚠️ If the request is "create X", "send Y", "process Z" with side effects → that's an Action; suggest `/action` instead.

## Step 2: Resolve Ambiguity

- Generic name (`OrderService`, `UserService`) → reject, propose a specific name (`PricingCalculator`, `OrderItemResolver`)
- Has side effects (persists, dispatches events) → redirect to `/action`
- Stateful → push back; services should be stateless

## Step 3: Build Context Blob

```
Context for service agent:
- Class: {DescriptiveName}  (NOT {Model}Service)
- Methods: [breakdown(int $subtotalCents, float $taxRate): array, ...]
- Dependencies (constructor): [CurrencyConverter]
- Stateless: yes
```

## Step 4: Delegate

Task tool, `subagent_type: "service"`, pass the blob.

## Step 5: Synthesize

Report the service path, its methods, injected dependencies, and that it's stateless with no side effects.

## When to Ask vs Assume

- Generic naming → reject and rename
- Stateless → enforce
- Side effects → redirect to `/action`
