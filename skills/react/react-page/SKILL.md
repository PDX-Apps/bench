---
description: Generate a route-level React page component (owns the route's data, loading/error/empty states, composes components). Use when the user wants a new page, screen, view, or route component.
argument-hint: [the page — what it shows]
---

You're the **/react-page** skill. Enrich and delegate to the `react-page` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Page `{Name}Page`; what it shows; route params; the data it loads
## Step 2: Resolve
- Detect where pages live + the query hook to call (exists or suggest `/react-query`).
## Step 3: Build context blob
```
- Page: {Name}Page.tsx
- Params: {useParams ids}
- Data: {useResource() query}
- Renders: {components}
```
## Step 4: Delegate
Task tool, `subagent_type: "react-page"`, pass the blob.
## Step 5: Synthesize
Report the page + four states; suggest registering via `/react-route`.
