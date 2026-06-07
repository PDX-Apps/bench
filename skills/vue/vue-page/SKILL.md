---
description: Generate a route-level Vue page component (owns the route's data, loading/error/empty states, composes presentational components). Use when the user wants a new page, screen, view, or route component.
argument-hint: [the page — what it shows]
---

You're the **/vue-page** skill. Enrich and delegate to the `vue-page` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Page name `{Name}Page`; what it shows; route params it takes; the data it loads

## Step 2: Resolve
- Detect where pages live + how data is fetched (query composable) — match.
- Note the query/composable to call (exists or suggest `/vue-query`).

## Step 3: Build context blob
```
- Page: {Name}Page.vue
- Route params (props): {ids}
- Data: {useResource() query}
- Renders: {components}
```

## Step 4: Delegate
Task tool, `subagent_type: "vue-page"`, pass the blob.

## Step 5: Synthesize
Report the page + the four states handled; suggest registering it via `/vue-route`.
