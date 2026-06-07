---
description: Generate a Laravel API Resource (JsonResource transformer). Use when the user wants ONLY a Resource (not the full HTTP stack). For full HTTP layer, use /laravel instead.
argument-hint: [what the user needs]
---

You're the **/resource** skill. Translate the user's API Resource request into an enriched delegation to the `resource` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Resource class name** — `{Model}Resource`
- **Model** being transformed
- **Fields to expose** (subset of model attributes)
- **Nested relations** (using `whenLoaded()` to avoid N+1)
- **Shape**: plain `JsonResource` (default) or `JsonApiResource` (JSON:API spec)?

## Step 2: Resolve Ambiguity

- Fields not specified → ask "Expose all model attributes or a subset?"
- Nested relations → wrap each with `whenLoaded()` (never load eagerly in a resource)
- JSON:API vs plain → default to `JsonResource` unless the user asks for JSON:API/sparse fieldsets

## Step 3: Build Context Blob

```
Context for resource agent:
- Class: {Model}Resource
- Model: {Model}
- Base: JsonResource | JsonApiResource
- Fields to expose:
    id, reference, status, total_cents, created_at
- Nested relations (use whenLoaded):
    items → {Model}ItemResource::collection
    user → UserResource
```

## Step 4: Delegate

Task tool, `subagent_type: "resource"`, pass the blob.

## Step 5: Synthesize

Report the resource path, fields exposed, relations included (with `whenLoaded`), and the base class used.

## When to Ask vs Assume

- `whenLoaded()` for relations → always
- Base class → `JsonResource` unless JSON:API is requested
