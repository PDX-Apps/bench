---
description: Generate a Pinia store (setup-store syntax) for shared client state. Use when the user wants a Pinia store, global/shared state, or a session/cart/ui store. (Server/API data → use /vue-query instead.)
argument-hint: [what state the store holds]
---

You're the **/vue-store** skill. Enrich and delegate to the `vue-store` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Store id `{name}` (`use{Name}Store`); the client state it holds, getters, actions
- If it's really server data (lists/entities from an API) → redirect to `/vue-query`.

## Step 2: Build context blob
```
- Store: use{Name}Store  (id: "{name}")
- State: {fields}
- Getters: {derived}
- Actions: {functions}
```

## Step 3: Delegate
Task tool, `subagent_type: "vue-store"`, pass the blob.

## Step 4: Synthesize
Report the store + its public surface; suggest `/vue-test`.
