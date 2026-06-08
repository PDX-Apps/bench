---
name: react-route
description: In an Inertia project, routing is Laravel's and navigation is Inertia's — not React Router.
---

This project uses **Inertia.js** (the `inertia` addon is active). Routes are Laravel
routes that return `Inertia::render`; navigation is `<Link>` / `router` from `@inertiajs/react`
(an XHR that swaps the page component) — there is no client React Router.

Build the route + render via `/inertia`. For navigation use `<Link href>` / `router.visit`,
partial reloads with `:only`, and `prefetch` — see the addon's `ROUTE-001` pattern.

Do not scaffold a React Router route, a React Router route tree, or a client route table. Redirect to `/inertia`.
