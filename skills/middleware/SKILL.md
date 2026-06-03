---
description: Generate Laravel HTTP middleware classes. Use whenever the user mentions middleware, request filters, request/response interception, throttling logic, custom auth checks at the HTTP layer, or anything that should run before/after controllers in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/middleware** skill. Translate the user's middleware request into an enriched delegation to the `middleware` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Audit, Auth, etc.)
- **Middleware class name** — descriptive (e.g., `CompleteJourneyMiddleware`, `EnsureFreshTokenMiddleware`)
- **When it runs**: before-controller (filtering) | after-controller (response wrapping) | terminating (post-response cleanup/logging)
- **Alias** for short route declarations (e.g., `complete-journey`)
- **Scope**: applied globally? to a route group? per-route?

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Http/Middleware/ 2>/dev/null
ls bootstrap/app.php 2>/dev/null   # Laravel 12 middleware registration lives here
```

## Step 3: Resolve Ambiguity

- Before/after/terminating unclear → ask: "Does it run before the controller (filter), after (modify response), or after response sent (logging/cleanup)?"
- Alias name unclear → propose one based on class name (e.g., `CompleteJourneyMiddleware` → `complete-journey`)
- Where to register → assume `bootstrap/app.php` global registration unless module-scoped (then module's RouteServiceProvider)

## Step 4: Build Context Blob

```
Context for middleware agent:
- Module: {Module}
- Class: {Name}Middleware
- Path: Modules/{Module}/app/Http/Middleware/{Name}Middleware.php
- Stage: before-controller | after-controller | terminating
- Dependencies to inject (constructor): [JourneyService, AuthService]
- Alias: {alias-name}
- Registration: bootstrap/app.php (global / group: api/web) | module RouteServiceProvider
- Existing siblings: [CompleteJourneyMiddleware.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:middleware"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Audit/app/Http/Middleware/CompleteJourneyMiddleware.php` (after-controller stage, injects `JourneyService`). Aliased `complete-journey` and added to API group in `bootstrap/app.php`."

## When to Ask vs Assume

- Laravel 12 registration in `bootstrap/app.php` → never ask, always
- Alias kebab-case from class name → assume; confirm only if user provided one
- Heavy work in middleware → reject, suggest deferring to a Job
