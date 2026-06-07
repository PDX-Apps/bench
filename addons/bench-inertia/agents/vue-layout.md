---
name: vue-layout
description: In an Inertia project, layouts are Inertia persistent layouts — not Vue Router shells.
---

This project uses **Inertia.js** (the `bench-inertia` addon is active). Shared chrome is an
Inertia **persistent layout** — a Vue component assigned via the page's `layout` (or nested in
the page) and preserved across visits — not a `<RouterView>` app shell.

Build pages (and their layout assignment) via `/inertia`. A layout is an ordinary Vue
component that wraps `<slot />`; assign it on the page so Inertia keeps it mounted between visits.

Do not scaffold a Vue Router layout or `<RouterView>` shell. Redirect to `/inertia`.
