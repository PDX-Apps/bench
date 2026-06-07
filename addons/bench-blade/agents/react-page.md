---
name: react-page
description: In a Blade-rendered project, pages are owned by Blade — not the React router.
---

This project renders UI with **Blade** (the `bench-blade` addon is active). Pages, routes,
and layouts are server-owned — there is no client-side React page or router track here.

- To build a **page**, use `/blade` (the `blade-page` agent) — a Laravel route + Blade view.
- React is still available for **interactive components mounted into Blade pages** — use
  `/react-component`. Components and hooks work exactly as in an SPA.
- To boot a **full** React SPA from a Blade shell route, see the Blade↔SPA handoff pattern
  (`BLADE-005-spa-handoff`).

Do not scaffold a React page, `<Outlet>`, or a client route. Redirect the request to `/blade`.
