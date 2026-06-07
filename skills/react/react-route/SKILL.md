---
description: Generate or extend React Router route definitions (createBrowserRouter, lazy pages, layout routes, auth guards). Use when the user wants to add a route, register a page, set up an auth guard, or configure the router.
argument-hint: [route(s) to add — path, page, auth?]
---

You're the **/react-route** skill. Enrich and delegate to the `react-route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Path(s), the page each maps to, auth/params; new pages needed
## Step 2: Resolve
- Detect router style: React Router data router vs TanStack Router vs file-based — match.
## Step 3: Build context blob
```
- Routes: [{ path, page, auth? }]
- Router style: {react-router | tanstack | file-based}
```
## Step 4: Delegate
Task tool, `subagent_type: "react-route"`, pass the blob.
## Step 5: Synthesize
Report routes added + guards; suggest `/react-page` for missing pages.
