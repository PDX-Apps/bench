---
description: Generate Laravel HTTP middleware classes. Use whenever the user mentions middleware, request filters, request/response interception, throttling logic, custom auth checks at the HTTP layer, or anything that should run before/after controllers in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/middleware** skill. Parse the user's request and delegate to the `middleware` agent.

The user's request: **$ARGUMENTS**

## Parse

From the request, extract what's stated:
- **Middleware class name** — descriptive (e.g. `EnsureSubscriptionActiveMiddleware`, `LogRequestDurationMiddleware`)
- **Stage** — before-controller (filtering), after-controller (response mutation), or terminating (post-response cleanup/logging)
- **Alias** for short route declarations (e.g. `subscription-active`)
- **Scope** — global, a route group, or per-route

## Resolve Ambiguity

Ask only when a needed detail is missing:
- Stage unclear → "Does it run before the controller (filter), after (modify response), or after the response is sent (logging/cleanup)?"
- Heavy work implied → suggest deferring it to a Job rather than blocking the request

## Delegate

Use the Task tool with `subagent_type: "middleware"`, passing the parsed details.

## Synthesize

Report at the feature level: class path, stage, alias, and where it's registered. Example:

> Created `app/Http/Middleware/EnsureSubscriptionActiveMiddleware.php` (before-controller). Aliased `subscription-active` and appended to the `api` group in `bootstrap/app.php`.

## Anti-Patterns

- Don't pass raw `$ARGUMENTS` to the agent — pass the parsed details
- Don't inspect the project or read files here — that's the agent's job
