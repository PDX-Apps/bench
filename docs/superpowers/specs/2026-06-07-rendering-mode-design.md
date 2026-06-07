# Rendering mode — design

**Date:** 2026-06-07
**Status:** approved (design); implementation pending
**Idea-bank source:** `docs/working-notes.md` → "Frontend rendering MODE — should it be a first-class axis?"

## Problem

Bench's `--frontend` axis is `vue | react | none`. It captures the *component framework* but not the *rendering model*. A project that renders its UI with **Blade** (optionally with embedded Vue/React "islands") is unserved on two fronts:

1. **Suppression** — a Blade project still has the full Vue/React SPA track loaded (`vue-page`, `vue-route`, `vue-layout`, client router + data patterns). A Vue-SPA project, conversely, should never see Blade guidance. The mismatched track is noise.
2. **Onboarding** — rendering model is never *asked*. A Blade/Livewire/Inertia user has to already know to add an addon by hand; `/bench-init` doesn't surface the choice the way it surfaces the framework.

Both matter equally. The goal is one coherent treatment that suppresses the wrong track **and** asks the question at init.

## Key insight: rendering is not the framework axis — it's one layer down

Blade and Vue are **not** mutually exclusive. A common setup renders pages with Blade while mounting Vue components as **islands** (interactive widgets), and a related setup has Blade boot a **full Vue SPA** from one shell route. So the suppression does not happen at the framework level. What actually differs is **who owns the URL → view mapping**:

| Layer | Vue SPA | Blade + Vue islands | Pure Blade |
|---|---|---|---|
| URL → view routing | Vue Router (client) | Laravel routes → Blade views | Laravel routes → Blade views |
| App shell / page composition | Vue pages + `<RouterView>` | Blade layouts | Blade layouts |
| Data fetching | client API layer (TanStack) | props from Blade / small fetches | server |
| **Component authoring** | **`.vue` SFCs** | **`.vue` SFCs (mounted as islands)** | n/a |

The bottom row is **shared** between SPA and Blade+islands. The top three rows are the **page-ownership slice** that the rendering mode swaps.

The base Vue track already separates along exactly this line:

- **Page-ownership slice (swappable):** `patterns/frontend/vue/base/routing/{LAYOUT,PAGE,ROUTE}-001*` + `data/QUERY-001*`, with agents `vue-layout`, `vue-page`, `vue-route`, `vue-query`.
- **Component-authoring slice (shared, always kept):** `components/`, `composables/`, `state/`, `styling/`, `types/`, `validation/`, `i18n/`, `testing/`, with agents `vue-component`, `vue-composable`, `vue-store`, `vue-validator`, `vue-i18n`, `vue-test`.

(React mirrors this: `react-page`, `react-route`, `react-layout`, `react-query` are the swappable slice.)

## Design

**No new "rendering axis" system.** Rendering mode is expressed through **two mechanisms Bench already has** — the addon/layering system and the concern system — composed with the existing `--frontend` axis.

### The two composed axes

- **Component framework** — `--frontend=vue|react|none`. Unchanged. *What* interactive UI is written in.
- **Page ownership / rendering** — expressed as an **addon** that replace-overrides the page-ownership slice. Near-term values: SPA (no addon) and Blade (`bench-blade`).

### The valid matrix (entirely from existing axes)

| `--frontend` | rendering addon | Result |
|---|---|---|
| vue / react | — | Standalone SPA (base default) |
| vue / react | bench-blade | Blade SSR + framework islands |
| none | bench-blade | Pure Blade |
| none | — | Backend-only |

### Work item 1 — bench-blade gains *suppression* (replace the page-ownership slice)

Today `bench-blade` only **adds** a parallel `/blade` track under `patterns/laravel/views/`. It does not suppress the Vue SPA-routing slice, so a Blade+islands project still surfaces `vue-page` / `vue-route` / `vue-layout`. To deliver the suppression half, bench-blade adds **same-path replace-overrides** for the page-ownership slice only:

- `agents/vue/vue-page.md`, `vue-route.md`, `vue-layout.md`, `vue-query.md` → replaced with short "pages/routes/layouts are owned by Blade — use `/blade`" redirects.
- The matching base patterns `patterns/frontend/vue/base/routing/*` and `data/QUERY-001*` → replaced with Blade-redirect content.
- React mirror: `agents/react/react-{page,route,layout,query}.md` + the matching React routing/data patterns.

**Left untouched** (islands keep working): `vue-component`, `vue-composable`, `vue-store`, `vue-validator`, `vue-i18n`, `vue-test` and their patterns (and React equivalents).

The existing additive Blade track stays: `skills/blade/`, `agents/blade-page.md`, `agents/blade-component.md`, `patterns/laravel/views/BLADE-00x`.

This is pure existing layering (same-path replace) — no new build code.

### Work item 2 — bench-blade owns the Blade → full-SPA **handoff** pattern (decision: B only)

A new pattern in bench-blade — `patterns/laravel/views/BLADE-005-spa-handoff.md` — documents the one repeatable, easy-to-get-wrong seam: a Blade shell that boots a **full** Vue/React SPA. It covers:

- the catch-all Laravel route (e.g. `/app/{any?}` → shell view),
- the shell Blade view (`<div id="app">` + `@vite`),
- passing the bootstrap payload (authenticated user, CSRF token, runtime config) from Blade into the SPA,
- where the client router's base path lives.

**Explicitly NOT owned:** per-widget island mount wiring (data-attribute mount points, `createApp(Widget).mount(el)` props/CSRF passing). Left to the team; revisit later if demand appears.

### Work item 3 — a core `rendering` concern (onboarding)

`concerns/rendering.md` — asked at `/bench-init`, the documented home for the choice:

```yaml
---
concern: rendering
title: Rendering model
order: 3   # before layout(5)/test(10) — other concerns can read the chosen mode
detect: ls resources/js/app.* 2>/dev/null >/dev/null && echo spa || (ls resources/views/*.blade.php 2>/dev/null >/dev/null && echo blade || echo spa)
questions:
  - id: mode
    ask: "How does your app render its UI?"
    options: [spa, blade]      # inertia, livewire deferred (see Extension point)
    default: detect
affects:
  - frontend/vue/base/routing/PAGE-001-pages.md
  - frontend/vue/base/routing/ROUTE-001-routes.md
  - frontend/vue/base/routing/LAYOUT-001-layouts.md
  - frontend/vue/base/data/QUERY-001-tanstack-query.md
output: config:.bench/rendering.yaml
---
```

Apply writes `.bench/rendering.yaml`:

```yaml
mode: blade   # or spa
```

`affects:` is listed so the interview can explain *what changes* (the page-ownership slice) when the user picks Blade. The concern itself only writes config — consistent with how concerns produce config/overrides and let the build react. It does **not** run `bench addon add`.

### Work item 4 — build reads `.bench/rendering.yaml` and maps mode → addon

`bench build` / `rebuild` reads `.bench/rendering.yaml` and folds the mapped addon into the **resolved addon set** before the existing dependency-expansion + install passes run:

- `mode: blade` → ensure `bench-blade` is in the resolved set (deps-first, de-duped — reuses the `depends_on.addons` expansion path).
- `mode: spa` (or no file) → no addon added.

Re-resolved on every `rebuild`, like the `.bench/` project-local auto-discovery — the config travels in the repo.

## Extension point (deferred, but the mechanism must accommodate)

Inertia, Livewire, and first-party meta-frameworks are **future `mode` values**, each a future addon of the **same shape** (replace the page-ownership slice; Inertia keeps the framework axis since it renders Vue/React components, Livewire maps framework→none). The design must not foreclose them:

- `rendering` concern's `mode` option list is extensible.
- The build's `mode → addon` map is a lookup table, extensible per mode.
- Inertia's addon would replace the routing/data slice with Inertia idioms (`Inertia::render`, `usePage`, form helper, shared props) while keeping component authoring.

These are **not built now.** Scope for this spec is **Blade SSR + Vue SPA** only.

## Out of scope

- Inertia / Livewire / meta-framework rendering addons (extension point noted above).
- Per-widget Vue-island mount wiring as an owned pattern (only the full-SPA handoff, item 2, is owned).
- A `--frontend=blade` core CLI axis. The framework axis stays `vue|react|none`; rendering is concern→config→addon.

## Affected / new files (implementation preview)

- **New:** `concerns/rendering.md`
- **New:** `addons/bench-blade/patterns/laravel/views/BLADE-005-spa-handoff.md`
- **New (replace-overrides in bench-blade):**
  - `addons/bench-blade/agents/vue/vue-page.md`, `vue-route.md`, `vue-layout.md`, `vue-query.md`
  - `addons/bench-blade/patterns/frontend/vue/base/routing/{LAYOUT,PAGE,ROUTE}-001*`, `data/QUERY-001*`
  - React mirror of the above
- **Modified:** `scripts/install.sh` (+ possibly `bin/bench` / `scripts/init-project.sh`) — read `.bench/rendering.yaml`, map mode→addon into the resolved set.
- **Modified docs:** `docs/architecture.md` (rendering as framework × page-ownership), `docs/addons.md` (bench-blade now suppresses + handoff), `addons/bench-blade/README.md`.
- **Working notes:** mark the rendering-mode idea-bank item resolved.

## Open questions

None blocking. The React-mirror replace-overrides are only meaningful when `--frontend=react`; for a first cut the Vue slice can land first and React follow in the same pattern.
