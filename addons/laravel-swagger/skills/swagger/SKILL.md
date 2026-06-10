---
description: Document a Laravel API as OpenAPI/Swagger — inferred from code with Scramble (default, zero-annotation) or via #[OA\...] annotations (l5-swagger). Use on "/swagger", "API docs", "OpenAPI/Swagger for this API", "document this endpoint", "generate API documentation".
argument-hint: [what to document, or "set up API docs"]
---

You're the **/swagger** skill. Turn the request into an enriched delegation to the `swagger` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Setting up API docs for the project, or documenting specific endpoints/classes?
- Which approach: **Scramble** (inference — the default) or **l5-swagger** (`#[OA\...]` annotations)? Detect from `composer.json` (`dedoc/scramble` vs `darkaonline/l5-swagger`); if neither, default to Scramble.

## Step 2: Resolve
- **Scramble path:** the docs come from FormRequests + API Resources + typed returns — so check those exist for the target endpoints (the agent improves them, not OA attributes).
- **Annotation path:** schemas are defined once on their class and **referenced** via `ref:` — never inline-duplicated.

## Step 3: Build context blob
```
- Approach: {scramble (default) | l5-swagger}
- Targets: { endpoints/controllers: [...], (annotation) models/requests/resources: [...] }
- Auth: {bearer/sanctum? }
- Existing schemas (don't duplicate): [...]
```

## Step 4: Delegate
Task tool, `subagent_type: "swagger"`, pass the blob.

## Step 5: Synthesize
Report the approach used, what was set up/annotated, and the docs URL (`/docs/api` for Scramble; `/api/documentation` for l5-swagger).

## Not covered by a pattern?

If the request needs a **laravel-swagger** capability this addon's patterns don't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "laravel-swagger" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
