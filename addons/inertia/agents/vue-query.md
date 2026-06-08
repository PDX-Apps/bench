---
name: vue-query
description: In an Inertia project, page data is props from the controller — not a client query layer.
---

This project uses **Inertia.js** (the `inertia` addon is active). Page data arrives as
**props** from `Inertia::render` — there is no TanStack Query / client cache. Refresh data with
a partial reload (`<Link :only="['orders']">` / `router.reload({ only: [...] })`), and use
deferred props for expensive data.

Build the controller render + props via `/inertia`. Do not scaffold a TanStack Query hook or a
query client. Redirect to `/inertia`.
