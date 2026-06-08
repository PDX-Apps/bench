---
name: vue-page
description: In a Blade-rendered project, pages are owned by Blade — not Vue Router.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Pages, routes,
and layouts are server-owned — there is no client-side Vue page or router track here.

- To build a **page**, use `/blade` (the `blade-page` agent) — a Laravel route + Blade view.
- Vue is still available for **interactive components mounted into Blade pages** — use
  `/vue-component`. Components, composables, and stores work exactly as in an SPA.
- To boot a **full** Vue SPA from a Blade shell route, see the Blade↔SPA handoff pattern
  (`BLADE-005-spa-handoff`).

Do not scaffold a Vue page, `<RouterView>`, or a client route. Redirect the request to `/blade`.
