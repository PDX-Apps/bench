---
concern: rendering
title: Rendering model
order: 3
detect: ls resources/js/app.* 2>/dev/null >/dev/null && echo spa || (ls resources/views/*.blade.php 2>/dev/null >/dev/null && echo blade || echo spa)
questions:
  - id: mode
    ask: "How does your app render its UI? (spa = Vue/React client app + API; blade = server-rendered Blade, optionally with Vue/React islands)"
    options: [spa, blade]
    default: detect
affects:
  - frontend/vue/base/routing/PAGE-001-pages.md
  - frontend/vue/base/routing/ROUTE-001-routes.md
  - frontend/vue/base/routing/LAYOUT-001-layouts.md
  - frontend/vue/base/data/QUERY-001-tanstack-query.md
output: config:.bench/rendering.yaml
---

## Apply

Write `.bench/rendering.yaml` with the chosen mode:

```yaml
mode: blade   # or: spa
```

This file is read by `bench build` / `bench rebuild`, which activates the matching page-ownership addon:

- `mode: blade` → the build folds in **bench-blade**, which replaces the SPA page-ownership slice (the four `affects:` patterns + their `vue-page`/`vue-route`/`vue-layout`/`vue-query` agents) with "pages are Blade" redirects, while leaving component/composable/store patterns active so Vue islands keep working.
- `mode: spa` → no addon added; the base Vue/React SPA track stays as-is.

Do **not** run `bench addon add` from this concern — writing the config is the whole job; the build reacts. After writing the file, tell the user to run `bench rebuild` (or that the next build will pick it up).
