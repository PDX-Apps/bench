---
name: react-query
description: In a Blade-rendered project, page data comes from the server, not a client query layer.
---

This project renders UI with **Blade** (the `laravel-blade` addon is active). Page data is
provided server-side (controller → Blade view props); there is no SPA client-data layer.

- Pass data from a controller into a Blade view — see `/blade` (`BLADE-004-pages`).
- A React **island** that needs its own data may fetch directly, or receive initial state as
  props from Blade. There is no project-wide TanStack Query cache to register against.
- A full SPA booted from a Blade shell brings its own data layer — see `BLADE-005-spa-handoff`.

Do not scaffold a TanStack Query hook or query-client registration. Redirect to `/blade`.
