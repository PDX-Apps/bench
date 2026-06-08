---
description: Generate a custom Laravel Eloquent query builder class (extends Builder<Model>). Use when the user mentions a query builder, reusable query scopes, chainable query methods, or wants to extract complex queries out of controllers/models.
argument-hint: [model + the query methods you want]
---

You're the **/query-builder** skill. Turn the request into an enriched delegation to the `query-builder` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Builder class `{Model}Builder`; the model it's for; the methods to add (e.g. `paid()`, `overdue()`, `forUser(int $id)`)

## Step 2: Resolve
- Model missing → suggest `/model` first.
- Methods unclear → ask which scopes/methods (with example signatures).
- Detect where models/builders live — tell the agent to match the project's layout.

## Step 3: Build context blob
```
- Builder: {Model}Builder  (for {Model})
- Methods: [paid(), overdue(), forUser(int $id)]
- Update the model to override newEloquentBuilder()
```

## Step 4: Delegate
Task tool, `subagent_type: "query-builder"`, pass the blob.

## Step 5: Synthesize
Report the builder + methods + the model override; show usage (`{Model}::query()->...`).
