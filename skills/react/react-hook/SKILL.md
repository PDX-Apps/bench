---
description: Generate a custom React hook (use* function for reusable stateful logic). Use when the user wants a custom hook, "use" function, or to extract stateful logic from a component.
argument-hint: [what the hook should do]
---

You're the **/react-hook** skill. Enrich the request and delegate to the `react-hook` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Name `use{Name}`; inputs and what it returns
- Stateful logic → hook. Pure function → suggest a util. Server data → suggest `/react-query`.

## Step 2: Build context blob
```
- Hook: use{Name}
- Inputs: {args}
- Returns: {object/tuple}
- Effects/cleanup: {yes/no}
```

## Step 3: Delegate
Task tool, `subagent_type: "react-hook"`, pass the blob.

## Step 4: Synthesize
Report the file + returned shape; suggest `/react-test use{Name}`.
