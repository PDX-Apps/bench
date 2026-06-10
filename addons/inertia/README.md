# inertia

**Inertia.js (v2)** — server-driven SPA for Laravel + Vue/React. Pages come from controllers as props; navigation is `<Link>`/`router` (no client router); forms use `useForm`.

## What it ships
- **Laravel patterns** — `INERTIA-001` pages (`Inertia::render`, shared props, deferred props), `INERTIA-002` forms (`useForm`, validation flow).
- **Frontend overrides** (replace, for both Vue + React) — `ROUTE-001` (Inertia navigation, no client router) and `QUERY-001` (page data = props, no query library).
- **`/inertia`** skill → **`inertia-page`** agent (builds the controller + page component together).

## When to use
Your app uses Inertia (Laravel + a Vue/React frontend) instead of a separate API + client-routed SPA. Installing this makes bench treat routing + data the Inertia way.

## Install
```bash
bench addon add inertia && bench rebuild
```
