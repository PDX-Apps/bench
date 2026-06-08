---
description: Define a Laravel Pennant feature flag — class-based or closure feature, scope-aware checks (Feature::active / when / for), gradual rollout, @feature Blade directive, and route middleware. Use when the user mentions feature flags, Pennant, toggles, A/B flags, gradual rollout, or @feature.
argument-hint: [the feature name + who it's scoped to (user / team / global)]
---

You're the **/feature** skill. Turn the request into an enriched delegation to the `feature` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse

- What is the feature name (e.g. `new-checkout`, `invoice-pdf-v2`)?
- What is the scope — per-user, per-team, or globally toggled (null scope)?
- What surfaces are needed: feature definition only, controller call sites, Blade `@feature`, route middleware, or some combination?
- Class-based or closure? Default to class-based unless the flag is trivially simple (one expression).

## Step 2: Resolve

- Feature name not given → ask; suggest a kebab-case slug matching the domain noun.
- Scope unclear → default to per-user (the authenticated user); note the alternative and ask only if the request clearly involves teams or a global toggle.
- `app/Features/` absent → the agent will create it; note this.

## Step 3: Build context blob

```
- Feature name: {feature-name}
- Form: class-based | closure
- Scope: user | team | global (null)
- Surfaces: [definition, controller check, Blade @feature, route middleware]
- Rich value? yes/no — if yes: possible values
- Gradual rollout? yes/no — if yes: percentage or criteria
```

## Step 4: Delegate

Task tool, `subagent_type: "feature"`, pass the blob.

## Step 5: Synthesize

Report the feature definition path, scope, call sites wired, and any follow-ups (migration, registration, purge reminder).
