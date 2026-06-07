---
description: Generate a Vue composable (use* function for reusable reactive logic). Use when the user wants a composable, "use" hook, shared reactive logic, or to extract stateful behavior out of a component.
argument-hint: [what the composable should do]
---

You're the **/vue-composable** skill. Enrich the request and delegate to the `vue-composable` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Name `use{Name}`; inputs (args) and what it returns
- Stateful reactive logic? → composable. Pure function? → suggest a util instead. Server data? → suggest `/vue-query`.

## Step 2: Build context blob
```
- Composable: use{Name}
- Inputs: {args}
- Returns: {refs/computed/functions}
- Lifecycle/cleanup needed: {yes/no}
```

## Step 3: Delegate
Task tool, `subagent_type: "vue-composable"`, pass the blob.

## Step 4: Synthesize
Report the file + the returned shape; suggest `/vue-test use{Name}`.
