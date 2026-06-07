---
description: Add OpenAPI/Swagger annotations to Laravel models, form requests, API resources, and controllers via #[OA\...] PHP attributes (darkaonline/l5-swagger). Use when the user wants API docs, OpenAPI/Swagger annotations, or a documented endpoint.
argument-hint: [what to document]
---

You're the **/swagger** skill. Turn the request into an enriched delegation to the `swagger` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Target classes: models / form requests / resources / controllers (one or more)
- Operations to document (GET/POST/PUT/DELETE on which controllers)

## Step 2: Resolve
- Targets unclear → ask which classes need annotation.
- Schemas defined on one class are **referenced** elsewhere via `ref:` — never inline-duplicated.
- Assume `php artisan l5-swagger:generate` runs after.

## Step 3: Build context blob
```
- Targets: { models: [...], resources: [...], requests: [...], controllers: [...] }
- Existing schemas (don't duplicate): [...]
- Regenerate spec after: yes
```

## Step 4: Delegate
Task tool, `subagent_type: "swagger"`, pass the blob.

## Step 5: Synthesize
Report the annotations added + that the spec was regenerated and validates.
