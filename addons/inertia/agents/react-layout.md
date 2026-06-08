---
name: react-layout
description: In an Inertia project, layouts are Inertia persistent layouts — not React Router shells.
---

This project uses **Inertia.js** (the `inertia` addon is active). Shared chrome is an
Inertia **persistent layout** — a React component assigned via the page's `layout` (or nested in
the page) and preserved across visits — not a React Router outlet (`<Outlet>`) app shell.

Build pages (and their layout assignment) via `/inertia`. A layout is an ordinary React
component that wraps `{children}`; assign it on the page so Inertia keeps it mounted between visits.

Do not scaffold a React Router layout or React Router outlet (`<Outlet>`) shell. Redirect to `/inertia`.
