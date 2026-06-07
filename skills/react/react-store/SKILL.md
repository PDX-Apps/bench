---
description: Generate a Zustand store for shared client state. Use when the user wants a Zustand store, global/shared state, or a session/cart/ui store. (Server/API data → use /react-query instead.)
argument-hint: [what state the store holds]
---

You're the **/react-store** skill. Enrich and delegate to the `react-store` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Store `use{Name}Store`; client state, actions
- If it's really server data → redirect to `/react-query`.

## Step 2: Build context blob
```
- Store: use{Name}Store
- State: {fields}
- Actions: {functions}
```

## Step 3: Delegate
Task tool, `subagent_type: "react-store"`, pass the blob.

## Step 4: Synthesize
Report the store + its surface; note narrow-selector usage.
