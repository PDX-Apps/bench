# laravel-blade

The **Laravel Blade UI track** — for server-rendered apps that use Blade instead of a Vue/React SPA.

## What it ships
- **Patterns** — `BLADE-001` components (anonymous + class-based), `BLADE-002` layouts (component-based, slots/stacks), `BLADE-003` forms (CSRF, validation errors, old input), `BLADE-004` pages (controller → view, collections, pagination).
- **`/blade`** skill → **`blade-component`** + **`blade-page`** agents.

## When to use
Your Laravel app renders HTML with Blade (optionally + Livewire/Alpine), not a JS SPA. If you use a SPA frontend, use bench's core `vue`/`react` track instead. Pair with **livewire** for reactive components.

## Rendering modes

laravel-blade supports three setups depending on `--frontend`:

- **Pure Blade** (`--frontend=none` + this addon) — the entire UI is Blade. No Vue/React skills or patterns are active.
- **Blade + framework islands** (`--frontend=vue|react` + this addon) — Blade owns pages, routes, and layouts. The SPA page-ownership agents (`vue-page`, `vue-route`, `vue-layout`, `vue-query` and React equivalents) are replace-overridden with redirects to `/blade`. Component, composable, hook, and store patterns stay active so Vue/React islands can be mounted into Blade pages.
- **Blade → full-SPA handoff** — a single Blade shell route bootstraps a full client-side SPA (catch-all route, shell view, bootstrap payload, client-router base path). See pattern `BLADE-005-spa-handoff`.

**Activation via the `rendering` concern:** at `bench init`, the `rendering` concern asks "How does your app render its UI? (`spa` | `blade`)". Answering `blade` writes `mode: blade` to `.bench/rendering.yaml`; `bench rebuild` then folds laravel-blade into the resolved addon set automatically. You can also activate manually:

## Install
```bash
bench addon add laravel-blade && bench rebuild
```
