---
description: Build a filterable/sortable API index endpoint with spatie/laravel-query-builder. Use when the user wants list/index filtering, sorting, ?filter[...] query params, relation includes, or sparse fieldsets on an API resource.
argument-hint: [model + which filters/sorts/includes to allow]
---

You're the **/query-builder** skill. Turn the request into an enriched delegation to the `query-builder` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- The `{Model}` / endpoint to make queryable.
- **Filters** to allow — and each one's kind: `exact` for ids/enums/booleans, partial for free text, a model `scope`, or a custom `callback`.
- **Sorts** to allow + the **default sort**; **includes** (relations); **sparse fields**, if any.

## Step 2: Resolve
- Model or controller missing → suggest `/model` or `/controller` first.
- Filter semantics unclear (exact vs partial) → ask, or infer from the column (id/enum/bool → exact; text → partial).
- Detect where the index endpoint lives so the agent edits the right controller.

## Step 3: Build context blob
```
- Model: {Model}   Endpoint: {Controller}@index
- Filters: [status: exact, reference: partial, placed_between: scope]
- Sorts: [created_at, total]   Default: -created_at
- Includes: [customer, lines]   Fields: [id, reference, status]
```

## Step 4: Delegate
Task tool, `subagent_type: "query-builder"`, pass the blob.

## Step 5: Synthesize
Report the endpoint + allow-lists + a sample request URL (`GET /orders?filter[status]=open&sort=-created_at&include=customer`).

## Not covered by a pattern?

If the request needs a **spatie-query-builder** capability this addon's pattern doesn't cover (an advanced or rarely-used feature), delegate to the `doc-lookup` agent (Task tool) with `{ topic, package: "spatie-query-builder" }`. It reads the package's current docs, returns grounded guidance, and — on your go-ahead — saves it as a project pattern so the next run has it.
