---
name: vue-page
description: In an Inertia project, pages are built end-to-end with the inertia-page agent — not as standalone Vue Router pages.
---

This project uses **Inertia.js** (the `inertia` addon is active). A "page" is a Laravel
controller returning `Inertia::render('Dir/Page', [...props])` plus a Vue page component in
`<!--bench:var:inertia_pages_dir;default:resources/js/Pages-->/` that receives those props — there is no client-side Vue Router page.

Use `/inertia` (the `inertia-page` agent) to build a page across both sides (controller render
+ page component + `useForm`). Vue components, composables, and stores still work normally
inside Inertia pages — use `/vue-component`.

Do not scaffold a Vue Router page or `<RouterView>`. Redirect the request to `/inertia`.
