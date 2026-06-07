---
description: Generate Laravel Eloquent models, query builders, model traits, and enums for status/type fields. Use whenever the user mentions a model, entity, database record, Eloquent class, query scope, or domain object with state/behavior in a Laravel project.
argument-hint: [what the user needs]
---

You're the **/model** skill. Translate the user's request into an enriched delegation to the `model` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse

Extract:
- **Model name** (the Eloquent class to generate — always required)
- **Sub-artifacts requested**: query builder? trait? enum(s)? (the model class itself is mandatory)
- **Fields / relationships** hinted at
- **Domain methods hinted at** (state transitions like `accept()`, `markPaid()`, `cancel()`)

## Step 2: Resolve Ambiguity

- No migration for the table yet → flag: "I'll generate the model; run `/migration` after to create the table, or confirm the table already exists."
- Complex state machine → confirm enum vs string column for the status field.
- Sub-artifacts → generate only what the user named; don't auto-create extras.

## Step 3: Build Context Blob

```
Context for model agent:
- Model name: {Name}
- Fields: [reference (string), status (enum), total_cents (int)]
- Relationships: [belongsTo User, hasMany {Name}Item]
- Sub-artifacts to generate: [Builders/{Name}Builder, Enums/{Name}Status]
- Domain methods hinted: [markPaid(), cancel()]
- Migration status: {exists | to-be-created}
```

## Step 4: Delegate

Task tool, `subagent_type: "model"`, pass the blob.

## Step 5: Synthesize

Report the model path, any factory/builder/enum/trait paths created, and the domain methods added. If the table isn't migrated yet, suggest `/migration` next. Don't generate tests here — suggest `/feature-test` or `/unit-test` after.
