---
description: Generate data-fetching hooks with TanStack Query (React Query) — useQuery/useMutation wrappers + query-key factory for a resource. Use when the user wants to fetch/cache API data, load a list/detail, or create/update/delete via the server.
argument-hint: [resource and operations, e.g. "users list + detail + create"]
---

You're the **/react-query** skill. Enrich and delegate to the `react-query` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Resource `{Resource}`; operations (list/detail/create/update/delete); entity/payload types

## Step 2: Resolve
- Detect the HTTP client (`@/lib/http`, axios instance) — match it.

## Step 3: Build context blob
```
- Resource: {Resource}
- Operations: {list/detail/create/...}
- Types: {exist or scaffold}
- HTTP client: {detected}
```

## Step 4: Delegate
Task tool, `subagent_type: "react-query"`, pass the blob.

## Step 5: Synthesize
Report the hooks + query-key factory; suggest wiring into a page.
