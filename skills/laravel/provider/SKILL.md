---
description: Generate or modify Laravel service providers (bindings, EventServiceProvider, RouteServiceProvider, custom providers). Use whenever the user mentions a service provider, container binding, singleton, boot logic, route registration, or wants to wire something up at the framework level in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/provider** skill. Translate the user's provider request into an enriched delegation to the `provider` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Provider class** — `{Name}ServiceProvider`
- **What's being registered** — container bindings (interface → implementation)? boot wiring (view composers, macros, gates, observers, route model bindings)? routes? rate limiters?
- **Binding style hints** — singleton vs transient, contextual, deferred

## Step 2: Resolve Ambiguity

- Purpose unclear → ask: "What does this provider register — bindings, boot wiring, routes, or event listeners?"
- New provider vs modify existing → confirm which.
- Event listeners / policies → these auto-discover; only generate an Event provider for explicit, non-discovered cases.

## Step 3: Build Context Blob

```
Context for provider agent:
- Provider class: {Name}ServiceProvider
- register(): [bindings: PaymentGateway::class => StripePaymentGateway::class (singleton)]
- boot(): [observers, route model bindings, macros, view composers]
- Deferrable: yes/no (binding-only, no boot/routes/events)
- Routes / rate limiters: [...]
```

## Step 4: Delegate

Task tool, `subagent_type: "provider"`, pass the blob.

## Step 5: Synthesize

Report the provider path, what it registers (bindings / boot wiring / routes), whether it's deferred, and that it was registered in `bootstrap/providers.php`.

## When to Ask vs Assume

- `register()` binds only; `boot()` for anything needing other services → always
- Auto-discovery for events/policies → assume; only generate an Event provider for explicit cases
- Registration in `bootstrap/providers.php` → `make:provider` appends it automatically
