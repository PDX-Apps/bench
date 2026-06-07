# QUERY-001 — Page data (Blade-rendered project)

This project renders UI with **Blade**. Page data is **not** managed by a client-side query
layer here.

Pass data from a controller into a Blade view — see `BLADE-004-pages` via `/blade`. A Vue
island that needs its own data may fetch directly or receive initial state as props from
Blade. There is no project-wide TanStack Query cache to register against.

A full SPA booted from a Blade shell brings its own data layer — see `BLADE-005-spa-handoff`.

Do not scaffold a TanStack Query hook or query-client registration.
