---
description: Generate or extend Vue Router route definitions (RouteRecordRaw, lazy pages, nested/layout routes, typed meta, guards). Use when the user wants to add a route, register a page, set up navigation guards, or configure the router.
argument-hint: [route(s) to add — path, page, auth?]
---

You're the **/vue-route** skill. Enrich and delegate to the `vue-route` agent.

The user's request: **$ARGUMENTS**

## Step 1: Parse
- Path(s), route `name`(s), the page component each maps to, auth/meta, params
- New page needed? → note it (the agent can stub it or you suggest `/vue-page`).

## Step 2: Resolve
- Detect the routing setup: a manual `RouteRecordRaw[]` vs file-based routing (unplugin-vue-router/Nuxt) — match it.

## Step 3: Build context blob
```
- Routes: [{ path, name, page, meta }]
- Auth/guards: {requiresAuth?}
- Routing style: {manual array | file-based}
```

## Step 4: Delegate
Task tool, `subagent_type: "vue-route"`, pass the blob.

## Step 5: Synthesize
Report the routes added + any guard/meta; suggest `/vue-page` for missing pages.
