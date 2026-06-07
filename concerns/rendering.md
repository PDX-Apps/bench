---
concern: rendering
title: Rendering model
order: 3
detect: ls resources/js/app.* 2>/dev/null >/dev/null && echo spa || (ls resources/views/*.blade.php 2>/dev/null >/dev/null && echo blade || echo spa)
questions:
  - id: mode
    ask: "How does your app render its UI? (spa = Vue/React client app + API; blade = server-rendered Blade, optionally with Vue/React islands; inertia = server-driven SPA via Inertia.js with Vue/React pages; livewire = Blade + Livewire reactive components)"
    options: [spa, blade, inertia, livewire]
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
mode: blade   # or: spa | inertia | livewire
```

This file is read by `bench build` / `bench rebuild`, which folds in the matching page-ownership addon (the addon ships same-path replace-overrides for the SPA page-ownership slice — the four `affects:` patterns + their `vue-page`/`vue-route`/`vue-layout`/`vue-query` agents and React equivalents — while leaving component/composable/hook/store patterns active):

- `mode: spa` → no addon added; the base Vue/React SPA track stays as-is.
- `mode: blade` → **bench-blade**: pages/routes/layouts become Blade; Vue/React components still mount as islands. Works with `--frontend=vue|react` (islands) or `--frontend=none` (pure Blade).
- `mode: inertia` → **bench-inertia**: routing + data become Inertia idioms (`Inertia::render`, `<Link>`, props); pages stay Vue/React components resolved by Inertia. Requires `--frontend=vue|react`.
- `mode: livewire` → **bench-livewire** (which depends on **bench-blade**): Blade owns pages/layouts, Livewire 3 (+ Volt) provides reactive components. Typically `--frontend=none`.

Do **not** run `bench addon add` from this concern — writing the config is the whole job; the build reacts. After writing the file, tell the user to run `bench rebuild` (or that the next build will pick it up).
