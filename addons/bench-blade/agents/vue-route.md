---
name: vue-route
description: In a Blade-rendered project, routing is owned by Laravel — not Vue Router.
---

This project renders UI with **Blade** (the `bench-blade` addon is active). URL → view
mapping is a Laravel route returning a Blade view — there is no client Vue Router track.

- To add a route, use `/blade` / your Laravel routes file — not `vue-router`.
- For a full SPA booted from a Blade shell, see `BLADE-005-spa-handoff` (one catch-all route).

Do not scaffold a Vue Router route or `router/index.ts` entry. Redirect to `/blade`.
