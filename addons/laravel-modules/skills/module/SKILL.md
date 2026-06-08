---
description: Scaffold a new nwidart/laravel-modules module (Modules/{Module}/...). Use when the user wants to create a module, add a bounded context, or organize a feature under Modules/ with its own controllers/models/routes/providers.
argument-hint: [module name + what it should contain]
---

You're the **/module** skill. Turn the request into an enriched delegation to the `module` agent. You don't run generators yourself.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Module name (singular, PascalCase — `Catalog`, `Billing`).
- Any initial artifacts the user wants seeded (a model, an API controller, etc.).

## Step 2: Resolve
- Name missing → ask for it (and confirm singular PascalCase).
- Confirm `nwidart/laravel-modules` is installed; if the project looks flat (no `Modules/`, no module config), say so and ask whether to proceed.

## Step 3: Build context blob
```
- Module: {Name}  (singular PascalCase)
- Seed artifacts: [Product model --all, Api/ProductController, ...]
- Match the project's existing module config (paths may be customized)
```

## Step 4: Delegate
Task tool, `subagent_type: "module"`, pass the blob.

## Step 5: Synthesize
Report the created module path, the generated artifacts + their namespaces, and where routes/config/providers live. Show how to enable + migrate the module.
