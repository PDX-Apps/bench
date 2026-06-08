---
name: react-route
description: In a Blade-rendered project, routing is owned by Laravel — not the React router.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). URL → view
mapping is a Laravel route returning a Blade view — there is no client React Router track.

- To add a route, use `/blade` / your Laravel routes file — not the React router.
- For a full SPA booted from a Blade shell, see `BLADE-005-spa-handoff` (one catch-all route).

Do not scaffold a React Router route or route-tree entry. Redirect to `/blade`.
