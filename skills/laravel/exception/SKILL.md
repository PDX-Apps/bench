---
description: Generate Laravel domain exception classes. Use whenever the user mentions a custom exception, error class, throwable, domain error (like "OrderAlreadyShipped", "InsufficientStock"), or needs to model a business-rule violation as a typed exception in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/exception** skill. Parse the user's request and delegate to the `exception` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Exception class name** — `{Condition}Exception` (e.g. `OrderAlreadyShippedException`, `InsufficientStockException`)
- **What it represents** — a business-rule violation (`DomainException`), a runtime/programmer error (`RuntimeException`), or a case Laravel already handles (auth → 403, model-not-found → 404)
- **Static factory names** the user hints at (`forOrder(...)`, `forUser(...)`)
- **Custom HTTP response?** — a non-500 status (e.g. 409 Conflict)

## Resolve Ambiguity

Ask only when a needed detail is missing:
- The case is a standard 404/403/422/401 → Laravel's built-ins already cover it; confirm a custom exception is really wanted
- Base class unclear → default `DomainException` for business rules; ask only if it isn't obviously a domain rule
- Custom `render()` → only when the HTTP status isn't 500

## Delegate

Use the Task tool with `subagent_type: "exception"`, passing the parsed details.

## Synthesize

Report at the feature level: class path, base class, factories, and any custom render/report. Example:

> Created `app/Exceptions/OrderAlreadyShippedException.php` extending `DomainException`, factory `forOrder(int $orderId)`, custom `render()` returning 409 with `{message, code: 'order_already_shipped'}`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
- Don't spin up a custom exception for a case Laravel's built-ins already handle (404/403/422/401)
