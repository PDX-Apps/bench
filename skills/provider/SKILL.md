---
description: Generate or modify Laravel service providers (module providers, EventServiceProvider, RouteServiceProvider, custom providers). Use whenever the user mentions a service provider, binding, container registration, boot logic, route registration, or wants to wire something up at the framework level in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/provider** skill. Translate the user's provider request into an enriched delegation to the `provider` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Module** (Audit, Bill, etc.)
- **Provider type**:
  - `module` — the module's main `{Module}ServiceProvider` (type-safe stub from MODULE-002)
  - `event` — `EventServiceProvider` for explicit listener registration (rare since auto-discovery)
  - `route` — `RouteServiceProvider` for module routes / route model bindings / rate limiters
  - `custom` — for service container bindings, view composers, macros
- **What's being registered** — bindings? events? routes? rate limiters? view composers?

## Step 2: Inspect

```bash
ls Modules/{Module}/ 2>/dev/null || echo "MODULE_MISSING"
ls Modules/{Module}/app/Providers/ 2>/dev/null
cat bootstrap/providers.php 2>/dev/null | head -20  # global provider registration
```

## Step 3: Resolve Ambiguity

- Provider type unclear → ask: "Module main provider, Event/Route provider, or a custom one?"
- "Replace default" vs "add new" → for `module` type, default is replace per MODULE-002
- Auto-discovery vs explicit → events auto-discover; only need EventServiceProvider for special cases

## Step 4: Build Context Blob

```
Context for provider agent:
- Module: {Module}
- Provider type: module | event | route | custom
- Class: {Name}ServiceProvider
- Path: Modules/{Module}/app/Providers/{Name}ServiceProvider.php
- Registers: [
    bindings: [InterfaceX::class => ImplY::class],
    events: [BillCreated => [Listener1, Listener2]],
    routes: [api → routes/api.php, web → routes/web.php],
    rate-limiters: [...],
  ]
- Registration in bootstrap/providers.php: needed yes/no (depends on module discovery)
- Existing siblings: [BillServiceProvider.php, RouteServiceProvider.php]
```

## Step 5: Delegate

Task tool, `subagent_type: "bench:provider"`, pass the blob.

## Step 6: Synthesize

> "Created `Modules/Bill/app/Providers/BillServiceProvider.php` using the type-safe stub from MODULE-002 (PHPDoc annotations, type guards for Psalm/PHPStan level 9). Registers translations, views, migrations. Module discovery handles registration; no edit to `bootstrap/providers.php` needed."

## When to Ask vs Assume

- Type-safe stub (MODULE-002) → assume always for module providers
- Auto-discovery → assume for events; only generate EventServiceProvider for explicit cases
- Module discovery → assume modules are registered via `nwidart/laravel-modules` discovery, not manually in bootstrap
