---
name: react-page
description: In an Inertia project, pages are built end-to-end with the inertia-page agent — not as standalone React Router pages.
---

This project uses **Inertia.js** (the `bench-inertia` addon is active). A "page" is a Laravel
controller returning `Inertia::render('Dir/Page', [...props])` plus a React page component in
`resources/js/Pages/` that receives those props — there is no client-side React Router page.

Use `/inertia` (the `inertia-page` agent) to build a page across both sides (controller render
+ page component + `useForm`). React components and hooks still work normally
inside Inertia pages — use `/react-component`.

Do not scaffold a React Router page or a React Router outlet (`<Outlet>`). Redirect the request to `/inertia`.
