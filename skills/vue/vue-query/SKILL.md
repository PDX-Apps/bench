---
description: Generate data-fetching composables with TanStack Query (Vue Query) — useQuery/useMutation wrappers + query-key factory for a resource. Use when the user wants to fetch/cache API data, load a list/detail, or create/update/delete via the server.
argument-hint: [resource and operations, e.g. "users list + detail + create"]
---

You're the **/vue-query** skill. Enrich and delegate to the `vue-query` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Resource `{Resource}`; operations (list / detail / create / update / delete)
- The entity/payload types (exist or scaffold)

## Step 2: Resolve
- Detect the data lib: TanStack Query (base) vs Pinia Colada (match if present) vs none (recommend one).
- Detect the HTTP client (`@/lib/http`, axios instance, etc.) — match it.

## Step 3: Build context blob
```
- Resource: {Resource}
- Operations: {list/detail/create/...}
- Types: {User, CreateUserPayload — exist or scaffold}
- Data lib + HTTP client: {detected}
```

## Step 4: Delegate
Task tool, `subagent_type: "vue-query"`, pass the blob.

## Step 5: Synthesize
Report the composables + query-key factory created; suggest wiring into a page.
