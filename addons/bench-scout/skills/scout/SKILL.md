---
description: Add Laravel Scout full-text search to a project — make a model Searchable, define toSearchableArray, configure the index/driver, and build search endpoints with filtering & pagination. Use when the user mentions Scout, full-text search, Algolia, Meilisearch, Typesense, or making a model searchable.
argument-hint: [the model to make searchable + the search endpoint you want]
---

You're the **/scout** skill. Turn the request into an enriched delegation to the `scout` agent. You don't write files.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Which model to make searchable?
- Which fields should be indexed / searched / filtered on?
- Search endpoint needed (controller + route)? Conditional indexing? Driver preference?

## Step 2: Resolve
- No model named → ask which model; suggest `/model` if it doesn't exist yet.
- Driver unknown → tell the agent to read `SCOUT_DRIVER` from config (default to `database` if unset) rather than assuming.
- Detect where models / controllers live and match the project's layout.

## Step 3: Build context blob
```
- Searchable model: {Model}
- Indexed fields: [reference, notes, status, customer_id, created_at]
- Conditional indexing? (e.g. only status=completed)
- Search endpoint? controller + route, with where()/paginate()
- Driver: database | meilisearch | typesense | algolia
```

## Step 4: Delegate
Task tool, `subagent_type: "scout"`, pass the blob.

## Step 5: Synthesize
Report the Searchable wiring + the search endpoint; show usage (`{Model}::search(...)`) and note any `.env`/config + the `scout:import` re-index step the user must run.
